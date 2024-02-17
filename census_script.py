import census2022microdata

def main():
    census_obj = census2022microdata.CensusMicrodata2022()
    url = census_obj.build_url()
    census_obj.send_request(url=url)
    census_obj.transform_dataframe()
    census_obj.load_to_database()
    census_obj.write_to_csv()
    
if __name__ == "__main__":
    main()