def get_census_schema():
    '''Returns two dictionaries representing the database schema.'''
    
    individual_dict = {
        'demographics': [
            'state', 'division', 'age', 'sex', 'race_group_1', 'race_group_2',
            'race_group_3', 'marital_status', 'disability'
        ],
        'education': [
            'school_enrollment', 'current_grade_level', 'attained_education'
        ],
        'employment': [
            'worker_class', 'usual_hrs_worked_per_week'
        ],
    }
    
    household_dict = {
        'languages': [
            'lang_spoken_at_home', 'non_engl_lang_spoken_at_home',
            'limited_engl_speaking_household'
        ],
        'tech_access': [
            'smartphone', 'telephone_service', 'cell_data_plan', 'computer',
            'tablet', 'intnt_access' ,'satellite_intnt_service',
            'high_speed_intnt', 'other_intnt_service'
        ],
        'transportation': [
            'num_of_vehicles'
        ],
        'income_costs': [
            'household_income', 'monthly_electricity_cost', 'monthly_gas_cost',
            'monthly_rent', 'property_taxes', 'annual_water_cost'
        ]
    }
    
    return individual_dict, household_dict