from flask import Flask, request, jsonify, Response
import json
import xmltodict

app = Flask(__name__)

@app.route('/json-to-xml', methods=['POST'])
def convert_json_to_xml():
    try:
        json_data = request.get_json()
        if json_data is None:
            return jsonify({'Error': 'Invalid JSON data'}), 400
        if isinstance(json_data, list):  # if json_data is list 
            wrapped_json_data = {'root': {'item': json_data}}
        else:
            wrapped_json_data = {'root': json_data}

        xml_data = xmltodict.unparse(wrapped_json_data, pretty=True)
        return Response(xml_data, mimetype='application/xml')

    except Exception as e:
        return jsonify({'Error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
