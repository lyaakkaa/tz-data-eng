import bs4
import requests
import xlsxwriter
import time

main_url = 'https://www.goszakup.gov.kz/'

data = [['Наименование организации', 'БИН организации', 'ФИО руководителя', 'ИИН руководителя', 'Полный адрес организации']]
seen_entries = set()  

def get_soup(url, retries=3, delay=5):
    attempt = 0
    while attempt < retries:
        try:
            print(f"Fetching URL: {url}, attempt {attempt + 1}/{retries}")
            res = requests.get(url)
            res.raise_for_status()
            print("Successfully fetched the URL.")
            return bs4.BeautifulSoup(res.text, 'html.parser')
        except requests.RequestException as e:
            print(f"Request error: {e}, attempt {attempt + 1}/{retries}")
            attempt += 1
            time.sleep(delay)
    print("Failed to fetch the URL after multiple attempts.")
    return None

def extract_supplier_details(supplier_url):
    print(f"Extracting details from: {supplier_url}")
    soup = get_soup(supplier_url)
    if not soup:
        print("No soup object returned. Skipping details extraction.")
        return None, None, None
    try:
        manager_tables = soup.find_all('table', class_='table-striped')
        fio, iin = None, None
        for table in manager_tables:
            rows = table.find_all('tr')
            for row in rows:
                header = row.find('th')
                if header:
                    header_text = header.get_text(strip=True)
                    if header_text == 'ИИН':
                        iin = row.find('td').get_text(strip=True)
                    elif header_text == 'ФИО':
                        fio = row.find('td').get_text(strip=True)
            if fio and iin:
                break

        contact_info = soup.find('div', class_='panel-heading', string='Контактная информация')
        contact_table = contact_info.find_next('table', class_='table-striped') if contact_info else None
        address = None
        if contact_table:
            address_row = contact_table.find_all('tr')[1] if len(contact_table.find_all('tr')) > 1 else None
            address = address_row.find_all('td')[2].get_text(strip=True) if address_row and len(address_row.find_all('td')) > 2 else None
            if address:
                print(f"Found address: {address}")
        
        return fio, iin, address
    except Exception as e:
        print(f"Error extracting details: {e}")
        return None, None, None

print(f"Fetching suppliers page: {main_url + 'registry/rqc?count_record=50&page=2'}")
suppliers_page = get_soup(main_url + 'registry/rqc?count_record=2000&page=1')
if suppliers_page:
    suppliers = suppliers_page.find_all('tr')[1:]  
    for supplier in suppliers:
        columns = supplier.find_all('td')
        if len(columns) >= 3:
            org_name = columns[1].get_text(strip=True)
            bin_number = columns[2].get_text(strip=True)
            supplier_url = columns[1].find('a')['href']
            full_url = requests.compat.urljoin(main_url, supplier_url) 
            fio, iin, address = extract_supplier_details(full_url)
            entry = (org_name, bin_number, fio, iin, address)
            
            if entry not in seen_entries:
                seen_entries.add(entry)
                data.append(list(entry))
            time.sleep(2) 

with xlsxwriter.Workbook('suppliers.xlsx') as workbook:
    worksheet = workbook.add_worksheet()
    for row_num, row_data in enumerate(data):
        worksheet.write_row(row_num, 0, row_data)

print("Data has been successfully saved to 'suppliers.xlsx'.")
