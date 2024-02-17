import uuid
from sys import exit
from census2022microdata.census_schema import get_census_schema

def _load_tables(df, table_group, connection):
    """ Loads the MSSQL 2022 Census Microdata database with data form the provided dataframe.

    Args:
        df (DataFrame): DataFrame containing data to be loaded.
        table_group (_type_): Individual or Household data as dictionaries.
        connection (_type_): Connection string to access the database.
    """
    
    individuals_ids = [uuid.uuid4() for _ in range(df.shape[0])]
    household_ids = [uuid.uuid4() for _ in range(df.shape[0])]
    
    for k, v in table_group.items():
        sub_df = df[v].copy()
        
        if 'demographics' in table_group.keys():
            sub_df.loc[:, 'id'] = individuals_ids
        elif k == 'income_costs':
            sub_df.loc[:, 'state'] = df['state'].copy()
            sub_df.loc[:, 'id'] = household_ids
        else:
            sub_df.loc[:, 'id'] = household_ids
            
        sub_df = sub_df.set_index('id', verify_integrity=True)
        sub_df.to_sql(name=k, con=connection, if_exists='append')

def load_database(df, connection):
    """ Transforms and loads the provided DataFrame into the MSSQL 2022 Census Micordata database.

    Args:
        df (DataFrame): DataFrame to be loaded.
    """
    try:
        individual, household = get_census_schema()
        _load_tables(df, individual, connection)
        _load_tables(df, household, connection)
    except ModuleNotFoundError:
        print('Module "census_schema.py" not found.')
        exit()
    except:
        print('Write to database was unsuccessful. :(')
    finally:
        print('Write to database was successful.')