import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  String getAcceptanceRateCategory(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    if (rate >= 75) return 'Very High';
    if (rate >= 50) return 'High';
    if (rate >= 25) return 'Moderate';
    return 'Low';
  }

  Color getAcceptanceRateColor(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    if (rate >= 75) return Colors.green;
    if (rate >= 50) return Colors.lightGreen;
    if (rate >= 25) return Colors.orange;
    return Colors.red;
  }

  Color getConfidenceColor(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getConfidenceIcon(String confidence) {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Icons.verified;
      case 'medium':
        return Icons.warning_amber;
      case 'low':
        return Icons.info_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String acceptanceRate = args['acceptance_rate'];
    final String confidence = args['confidence'] ?? 'Unknown';
    final Map<String, dynamic>? similarCasesInfo = args['similar_cases_info'];
    final Map<String, dynamic>? encodedFeatures = args['encoded_features'];
    final String? note = args['note'];
    final String country = args['country'];
    final String origin = args['origin'];
    final String year = args['year'];
    final String procedureType = args['procedure_type'] ?? '';
    final String appliedDuringYear = args['applied_during_year'] ?? '';
    final String pendingStart = args['pending_start'] ?? '';
    final String unhcrAssistedStart = args['unhcr_assisted_start'] ?? '';
    final String decisionsOther = args['decisions_other'] ?? '';

    final category = getAcceptanceRateCategory(acceptanceRate);
    final color = getAcceptanceRateColor(acceptanceRate);
    final confidenceColor = getConfidenceColor(confidence);

    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction Results'),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Main Result Card
              Card(
                elevation: 8,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 60,
                        color: color,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Predicted Acceptance Rate',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        acceptanceRate,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          '$category Acceptance Rate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: confidenceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: confidenceColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(getConfidenceIcon(confidence), color: confidenceColor, size: 18),
                            SizedBox(width: 8),
                            Text(
                              '$confidence Confidence',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: confidenceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (note != null && note.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.amber.shade700, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      Divider(),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('Origin', style: TextStyle(color: Colors.grey.shade600)),
                              Text(origin, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Destination', style: TextStyle(color: Colors.grey.shade600)),
                              Text(country, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('Year', style: TextStyle(color: Colors.grey.shade600)),
                              Text(year, style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      if (similarCasesInfo != null) ...[
                        SizedBox(height: 16),
                        Divider(),
                        SizedBox(height: 16),
                        Text(
                          'Historical Data Analysis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Similar Cases', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text('${similarCasesInfo['count'] ?? 0}', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (similarCasesInfo['avg_acceptance_rate'] != null)
                              Column(
                                children: [
                                  Text('Avg Rate', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  Text('${(similarCasesInfo['avg_acceptance_rate'] * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            if (similarCasesInfo['years_available'] != null && similarCasesInfo['years_available'].isNotEmpty)
                              Column(
                                children: [
                                  Text('Data Years', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  Text('${similarCasesInfo['years_available'].length}', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Prediction Details Card
              Card(
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.data_usage, color: Colors.blue.shade600, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Prediction Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildDetailRow('Procedure Type', procedureType),
                      _buildDetailRow('Applications During Year', appliedDuringYear),
                      _buildDetailRow('Pending Start-Year', pendingStart),
                      _buildDetailRow('UNHCR Assisted Start-Year', unhcrAssistedStart),
                      _buildDetailRow('Other Decisions', decisionsOther),
                      if (encodedFeatures != null) ...[
                        SizedBox(height: 12),
                        Divider(),
                        SizedBox(height: 12),
                        Text(
                          'Model Encoding',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text('Country', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text('${encodedFeatures['country_encoded']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Origin', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text('${encodedFeatures['origin_encoded']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              children: [
                                Text('Procedure', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                Text('${encodedFeatures['procedure_encoded']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Healthcare Impact
              Card(
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_hospital, color: Colors.red.shade600, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Healthcare Impact',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildImpactSection('Upsides', _getHealthcareUpsides(acceptanceRate), Colors.green),
                      SizedBox(height: 12),
                      _buildImpactSection('Challenges', _getHealthcareDownsides(acceptanceRate), Colors.orange),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Education Impact
              Card(
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.school, color: Colors.blue.shade600, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Education Impact',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildImpactSection('Upsides', _getEducationUpsides(acceptanceRate), Colors.green),
                      SizedBox(height: 12),
                      _buildImpactSection('Challenges', _getEducationDownsides(acceptanceRate), Colors.orange),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Mental Health Impact
              Card(
                elevation: 6,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.purple.shade600, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Mental Health Impact',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildImpactSection('Upsides', _getMentalHealthUpsides(acceptanceRate), Colors.green),
                      SizedBox(height: 12),
                      _buildImpactSection('Challenges', _getMentalHealthDownsides(acceptanceRate), Colors.orange),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/predict', (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('New Prediction', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Home', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value.isEmpty ? 'N/A' : value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                title == 'Upsides' ? Icons.check_circle : Icons.warning,
                color: color,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  List<String> _getHealthcareUpsides(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    
    if (rate >= 75) {
      return [
        'High likelihood of accessing comprehensive healthcare services',
        'Greater chance of receiving specialized medical treatment',
        'Access to preventive care and regular health checkups',
        'Integration into national health insurance systems',
        'Reduced medical costs due to subsidized healthcare',
      ];
    } else if (rate >= 50) {
      return [
        'Moderate access to essential healthcare services',
        'Opportunity for emergency medical treatment',
        'Access to maternal and child health services',
        'Potential inclusion in community health programs',
      ];
    } else if (rate >= 25) {
      return [
        'Limited access to basic healthcare services',
        'Emergency medical care availability',
        'Some access to NGO-provided health services',
      ];
    } else {
      return [
        'Access to emergency medical care only',
        'Some humanitarian health assistance available',
      ];
    }
  }

  List<String> _getHealthcareDownsides(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    
    if (rate >= 75) {
      return [
        'May face language barriers in healthcare settings',
        'Cultural differences in medical practices',
        'Initial unfamiliarity with healthcare system navigation',
      ];
    } else if (rate >= 50) {
      return [
        'Limited access to specialized care',
        'Potential delays in non-emergency treatments',
        'Language barriers affecting healthcare communication',
        'May not qualify for all health benefits immediately',
      ];
    } else if (rate >= 25) {
      return [
        'Significant barriers to accessing quality healthcare',
        'Limited insurance coverage or high out-of-pocket costs',
        'Long waiting times for medical appointments',
        'Restricted access to mental health services',
        'Difficulty obtaining prescription medications',
      ];
    } else {
      return [
        'Severe limitations in healthcare access',
        'High risk of untreated medical conditions',
        'Dependence on emergency services for basic care',
        'Limited or no access to chronic disease management',
        'High medical expenses without insurance coverage',
        'Risk of deteriorating health conditions',
      ];
    }
  }

  List<String> _getEducationUpsides(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    
    if (rate >= 75) {
      return [
        'Full access to public education system',
        'Opportunity for higher education and university admission',
        'Access to vocational training and skill development programs',
        'Language learning support and integration programs',
        'Scholarship opportunities for academic excellence',
        'Recognition of previous educational qualifications',
      ];
    } else if (rate >= 50) {
      return [
        'Access to primary and secondary education',
        'Some vocational training opportunities',
        'Language learning programs available',
        'Community education initiatives',
        'Adult education programs',
      ];
    } else if (rate >= 25) {
      return [
        'Limited access to basic education',
        'Some NGO-provided educational programs',
        'Informal learning opportunities',
        'Community-based education initiatives',
      ];
    } else {
      return [
        'Very limited educational opportunities',
        'Some humanitarian education programs',
        'Basic literacy programs where available',
      ];
    }
  }

  List<String> _getEducationDownsides(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    
    if (rate >= 75) {
      return [
        'Language barriers in academic settings',
        'Need for educational credential recognition',
        'Cultural adaptation in learning environments',
        'Potential gaps in educational background',
      ];
    } else if (rate >= 50) {
      return [
        'Limited access to higher education',
        'Language barriers affecting academic performance',
        'Difficulty in credential recognition',
        'Reduced access to specialized educational programs',
        'Financial constraints for educational materials',
      ];
    } else if (rate >= 25) {
      return [
        'Significant barriers to quality education',
        'Limited school enrollment opportunities',
        'Language barriers severely impacting learning',
        'Lack of educational resources and materials',
        'Interrupted education due to uncertain status',
      ];
    } else {
      return [
        'Severe educational exclusion',
        'Children at risk of losing educational opportunities',
        'No access to formal education systems',
        'High likelihood of educational regression',
        'Limited future career prospects due to education gaps',
        'Increased risk of child labor instead of schooling',
      ];
    }
  }

  List<String> _getMentalHealthUpsides(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    
    if (rate >= 75) {
      return [
        'Access to comprehensive mental health services',
        'Reduced anxiety about legal status and future',
        'Greater sense of security and stability',
        'Access to trauma counseling and therapy',
        'Community integration support programs',
        'Family reunification opportunities',
        'Improved overall well-being and hope for the future',
      ];
    } else if (rate >= 50) {
      return [
        'Moderate access to mental health support',
        'Some reduction in uncertainty-related stress',
        'Access to community support groups',
        'Basic counseling services available',
        'Improved sense of security',
      ];
    } else if (rate >= 25) {
      return [
        'Limited mental health support available',
        'Some community-based psychosocial support',
        'Peer support networks',
        'Basic stress management resources',
      ];
    } else {
      return [
        'Minimal mental health support',
        'Some humanitarian psychosocial assistance',
        'Peer support within refugee communities',
      ];
    }
  }

  List<String> _getMentalHealthDownsides(String percentage) {
    final rate = double.tryParse(percentage.replaceAll('%', '')) ?? 0;
    
    if (rate >= 75) {
      return [
        'Initial cultural adaptation stress',
        'Potential survivor guilt',
        'Adjustment challenges in new environment',
        'Language barriers affecting mental health communication',
      ];
    } else if (rate >= 50) {
      return [
        'Ongoing uncertainty about future status',
        'Limited access to specialized mental health care',
        'Cultural barriers to seeking mental health support',
        'Separation from extended family and support networks',
        'Stress from integration challenges',
      ];
    } else if (rate >= 25) {
      return [
        'High levels of anxiety about uncertain future',
        'Limited mental health resources and support',
        'Chronic stress from insecure legal status',
        'Depression due to prolonged uncertainty',
        'Trauma responses without adequate treatment',
        'Social isolation and discrimination',
      ];
    } else {
      return [
        'Severe psychological distress from rejection risk',
        'Chronic anxiety and depression',
        'High risk of PTSD without treatment',
        'Despair and hopelessness about the future',
        'Suicidal ideation risks',
        'Family separation trauma',
        'Complete lack of mental health support systems',
        'Deteriorating psychological well-being',
      ];
    }
  }
}