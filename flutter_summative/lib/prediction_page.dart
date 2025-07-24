import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController appliedController = TextEditingController();
  final TextEditingController pendingController = TextEditingController();
  final TextEditingController unhcrController = TextEditingController();
  final TextEditingController decisionsController = TextEditingController();

  String? country;
  String? origin;
  String? procedureType;
  String? resultMessage = '';

  bool isLoadingData = false;

  // All African countries
  final List<String> africanCountries = [
    'Algeria', 'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi',
    'Cabo Verde', 'Cameroon', 'Central African Republic', 'Chad', 'Comoros',
    'Congo', 'DR Congo', 'Djibouti', 'Egypt', 'Equatorial Guinea', 'Eritrea',
    'Eswatini', 'Ethiopia', 'Gabon', 'Gambia', 'Ghana', 'Guinea', 'Guinea-Bissau',
    'Ivory Coast', 'Kenya', 'Lesotho', 'Liberia', 'Libya', 'Madagascar',
    'Malawi', 'Mali', 'Mauritania', 'Mauritius', 'Morocco', 'Mozambique',
    'Namibia', 'Niger', 'Nigeria', 'Rwanda', 'Sao Tome and Principe',
    'Senegal', 'Seychelles', 'Sierra Leone', 'Somalia', 'South Africa',
    'South Sudan', 'Sudan', 'Tanzania', 'Togo', 'Tunisia', 'Uganda',
    'Zambia', 'Zimbabwe'
  ];

  // Procedure types based on UNHCR data
  final List<String> procedureTypes = [
    'G / FI', 'U / FI', 'C / TR', 'G / EO', 'G / IN', 'U / EO', 'U / IN'
  ];

  Future<void> predict() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('https://summative-ml.onrender.com/predict');
    final body = {
      "country": country!,
      "origin": origin!,
      "procedure_type": procedureType!,
      "year": int.parse(yearController.text),
      "applied_during_year": int.parse(appliedController.text),
      "pending_start": int.parse(pendingController.text),
      "unhcr_assisted_start": int.parse(unhcrController.text),
      "decisions_other": int.parse(decisionsController.text),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json.containsKey('predicted_acceptance_rate')) {
          // Navigate to results page with the enhanced prediction data
          Navigator.pushNamed(
            context, 
            '/results',
            arguments: {
              'acceptance_rate': json['prediction_percentage'],
              'confidence': json['confidence'] ?? 'Unknown',
              'similar_cases_info': json['similar_cases_info'],
              'encoded_features': json['encoded_features'],
              'note': json['note'],
              'country': country!,
              'origin': origin!,
              'year': yearController.text,
              'procedure_type': procedureType!,
              'applied_during_year': appliedController.text,
              'pending_start': pendingController.text,
              'unhcr_assisted_start': unhcrController.text,
              'decisions_other': decisionsController.text,
            }
          );
        } else {
          setState(() {
            resultMessage = "Error: ${json['detail'] ?? json['error'] ?? 'Unknown error'}";
          });
        }
      } else {
        final json = jsonDecode(response.body);
        setState(() {
          resultMessage = "API Error (${response.statusCode}): ${json['detail'] ?? json['error'] ?? 'Server error'}";
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = "Connection Error: $e";
      });
    }
  }

  Future<Map<String, int>?> fetchHistoricalData(String selectedCountry, String selectedOrigin, int year) async {
    try {
      setState(() {
        isLoadingData = true;
      });

      final url = Uri.parse('https://summative-ml.onrender.com/historical-data');
      final body = {
        "country": selectedCountry,
        "origin": selectedOrigin,
        "year": year,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json.containsKey('success') && json['success'] == true && json.containsKey('data')) {
          return {
            'applied_during_year': json['data']['applied_during_year'] ?? 0,
            'pending_start': json['data']['pending_start'] ?? 0,
            'unhcr_assisted_start': json['data']['unhcr_assisted_start'] ?? 0,
            'decisions_other': json['data']['decisions_other'] ?? 0,
          };
        } else {
          print('Historical data response: ${json['error'] ?? 'No data found'}');
        }
      } else {
        print('Historical data API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching historical data: $e');
    } finally {
      setState(() {
        isLoadingData = false;
      });
    }
    
    return null;
  }

  void updateDataBasedOnSelections() async {
    if (country != null && origin != null && yearController.text.isNotEmpty) {
      final selectedYear = int.parse(yearController.text);
      
      final historicalData = await fetchHistoricalData(country!, origin!, selectedYear);
      
      if (historicalData != null) {
        setState(() {
          appliedController.text = historicalData['applied_during_year'].toString();
          pendingController.text = historicalData['pending_start'].toString();
          unhcrController.text = historicalData['unhcr_assisted_start'].toString();
          decisionsController.text = historicalData['decisions_other'].toString();
        });
      } else {
        // Set default values to zero if no historical data found
        setState(() {
          appliedController.text = '0';
          pendingController.text = '0';
          unhcrController.text = '0';
          decisionsController.text = '0';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No historical data found. Default values set to zero.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make a Prediction'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Country of Asylum/Residence',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            items: africanCountries.map((val) =>
                              DropdownMenuItem(child: Text(val), value: val)).toList(),
                            onChanged: (val) {
                              setState(() {
                                country = val;
                              });
                              updateDataBasedOnSelections();
                            },
                            validator: (val) => val == null ? 'Please select a country' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Country of Origin',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.flag),
                            ),
                            items: africanCountries.map((val) =>
                              DropdownMenuItem(child: Text(val), value: val)).toList(),
                            onChanged: (val) {
                              setState(() {
                                origin = val;
                              });
                              updateDataBasedOnSelections();
                            },
                            validator: (val) => val == null ? 'Please select an origin' : null,
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'RSD Procedure Type',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.assignment),
                            ),
                            items: procedureTypes.map((val) =>
                              DropdownMenuItem(child: Text(val), value: val)).toList(),
                            onChanged: (val) => setState(() => procedureType = val),
                            validator: (val) => val == null ? 'Please select a procedure type' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: yearController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Select Year',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                                initialDatePickerMode: DatePickerMode.year,
                              );

                              if (picked != null) {
                                yearController.text = picked.year.toString();
                                updateDataBasedOnSelections();
                              }
                            },
                            validator: (val) => val == null || val.isEmpty ? 'Select a year' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistical Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: appliedController,
                            decoration: InputDecoration(
                              labelText: 'Applied during year',
                              helperText: isLoadingData ? 'Loading data...' : 'Auto-filled from historical data',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people_outline),
                              suffixIcon: isLoadingData ? SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ) : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Enter a number' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: pendingController,
                            decoration: InputDecoration(
                              labelText: 'Total pending start-year',
                              helperText: isLoadingData ? 'Loading data...' : 'Auto-filled from historical data',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.pending_actions),
                              suffixIcon: isLoadingData ? SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ) : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Enter a number' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: unhcrController,
                            decoration: InputDecoration(
                              labelText: 'UNHCR-assisted at start-year',
                              helperText: isLoadingData ? 'Loading data...' : 'Auto-filled from historical data',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.support),
                              suffixIcon: isLoadingData ? SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ) : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Enter a number' : null,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: decisionsController,
                            decoration: InputDecoration(
                              labelText: 'Other decisions made',
                              helperText: isLoadingData ? 'Loading data...' : 'Auto-filled from historical data',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.gavel),
                              suffixIcon: isLoadingData ? SizedBox(
                                width: 16,
                                height: 16,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ) : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Enter a number' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: predict,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Predict Acceptance Rate', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (resultMessage!.isNotEmpty) 
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: resultMessage!.contains('Error') ? Colors.red.shade50 : Colors.green.shade50,
                        border: Border.all(
                          color: resultMessage!.contains('Error') ? Colors.red : Colors.green,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            resultMessage!.contains('Error') ? Icons.error : Icons.check_circle,
                            color: resultMessage!.contains('Error') ? Colors.red : Colors.green,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              resultMessage!, 
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: resultMessage!.contains('Error') ? Colors.red : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}