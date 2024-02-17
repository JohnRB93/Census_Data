import requests
import pandas as pd
import json
import os
import sys
import sqlalchemy
from census2022microdata.states import get_state_codes_dict
from census2022microdata.load_sql_database import load_database

class CensusMicrodata2022:
    """ Handles the process of census api requests and storing the data into a database.
    """
    
    def __init__(self):
        self.states_dict = get_state_codes_dict()
        self.connection = None
        self.user_state = None
        self.df = None
        self.vars_dict = None
        
    def _generate_connection(self):
        """ Generates a connection to the MSSQL 2022 Census Microdata database.

        Returns:
        string: Connection String.
        """
        connection_string = f'mssql+pyodbc://{os.environ.get("SQL_AUTH")}/Census_2022_Microdata?driver=ODBC+Driver+17+for+SQL+Server'
        engine = sqlalchemy.create_engine(connection_string)
        return engine.connect()
        
    def _state_duplicates(self, state):
        """ Checks if the database already has data for the user's requested state.

        Args:
            state (string): User's requested state.

        Returns:
            boolean: True if the user's requested state is already in the database.
        """
        statement = 'SELECT DISTINCT state FROM demographics'
        self.connection = self._generate_connection()
        sql_df = pd.read_sql(sql=statement, con=self.connection)
        self.connection.close()
        return state in list(sql_df['state'].apply(lambda s: str.lower(s)))
        
    def _get_user_input(self):
        """ Requests the user to input which state they want to get data for.

        Returns:
            string: User's requested state.
        """
        states_list = [s.lower() for s in self.states_dict.values()]
        
        while True:
            user_input = input('Enter state you want to send a request for, "q" to quit: ').lower()
            if user_input == 'q':
                print('Quitting Program.')
                sys.exit()
            elif user_input in states_list:
                if self._state_duplicates(user_input) == False:
                    return user_input
                else:
                    print('Data for {} is already in the database.'.format(user_input))
            else:
                print('Incorrect input, please input one of the states below, or "q" to quit:')
                print(states_list)

    def build_url(self):
        """ Generates the url string for the request based on the user's requested state.

        Returns:
            string: Url to send to request.
        """
        base_url = 'http://api.census.gov/data/2022/acs/acs1/pums'

        with open(r'schema\data_dictionary.json', 'r') as json_file:
            self.var_dict = dict(json.load(json_file))

        get_vars = '?get=' + ','.join([k for k in self.var_dict.keys()])
        self.user_state = self._get_user_input()
        code_val_pair = []

        for k, v in get_state_codes_dict().items():
            vl = v.lower()
            if self.user_state == vl:
                code_val_pair = [k, v]
                break
                
        for_state = '&for=state:' + code_val_pair[0]
        api_key = '&key=' + os.environ.get('CENSUS_API')
        return base_url + get_vars + for_state + api_key
        
    def send_request(self, url):
        """ Sends a request with the passed url and stores the returned data in a DataFrame.
            Once this function is successfully run, the DataFrame will be available with the get_dataframe() method.

        Args:
            url (string): Url to send the request with.
        """
        r = requests.get(url=url)
        self.df = pd.DataFrame(columns=r.json()[0], data=r.json()[1:])
        
    def get_dataframe(self):
        """ Returns the DataFrame, call only after successfully calling send_request().
        """
        return self.df
        
    def _rename_columns(self):
        """ Renames the columns of the dataframe so they're easier to understand.

        Returns:
            DataFrame: DataFrame with new column names
        """
        new_columns = [
            'division', 'sex', 'age', 'race_group_1', 'race_group_2', 'race_group_3',
            'marital_status', 'disability', 'lang_spoken_at_home', 'non_engl_lang_spoken_at_home',
            'limited_engl_speaking_household', 'smartphone', 'telephone_service',
            'cell_data_plan', 'computer', 'tablet', 'intnt_access', 'satellite_intnt_service',
            'high_speed_intnt', 'other_intnt_service', 'school_enrollment', 'current_grade_level',
            'attained_education', 'num_of_vehicles', 'worker_class', 'usual_hrs_worked_per_week',
            'household_income', 'monthly_electricity_cost', 'monthly_gas_cost', 
            'monthly_rent', 'property_taxes', 'annual_water_cost', 'state'
        ]
        old_columns = list(self.df.columns)
        col_renames = dict(zip(old_columns, new_columns))
        return self.df.rename(columns=col_renames)

    def transform_dataframe(self):
        """ Replaces the coded number values in each column with thier descriptions and replaces the column names with more readable names.
        """
        for k, v in self.var_dict.items():
            if type(v) is dict:
                for vv in v.values():
                    self.df[k] = self.df[k].replace(vv)
                    
        self.df['state'] = self.df['state'].replace(self.states_dict)
        self.df = self._rename_columns()

    def write_to_csv(self):
        """ Writes the object's dataframe to a .csv file.
        """
        self.df.to_csv('csv_data\\' + self.user_state.lower() + '_census.csv', index=False)

    def load_to_database(self):
        """ Loads the object's datafrom to the database.
        """
        self.connection = self._generate_connection()
        load_database(df=self.df, connection=self.connection)
        self.connection.close()