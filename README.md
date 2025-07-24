# Refugee Acceptance Analysis

## Mission & Problem Statement

This project addresses the critical humanitarian challenge of predicting refugee acceptance rates across different countries and origins. By analyzing historical asylum data including country of residence, origin, procedure types, and application volumes, our machine learning model helps humanitarian organizations, policymakers, and refugees themselves make informed decisions about asylum applications. The system leverages Random Forest algorithms to predict acceptance probabilities, enabling better resource allocation and strategic planning in refugee assistance programs. Our goal is to provide transparent, data-driven insights that support fair and efficient refugee protection processes worldwide.

My mission is to help refugees and minority groups have equal opportunities and resources like the other people.

## 🚀 Live API Endpoint

**Base URL:** `https://summative-ml.onrender.com/predict`

**Swagger UI Documentation:** [(https://summative-ml.onrender.com)/docs]


### Example API Request:

```bash
curl -X POST "https://refugee-predictor-api.herokuapp.com/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "country": "Germany",
    "origin": "Syria",
    "procedure_type": "Regular procedure",
    "year": 2024,
    "applied_during_year": 5000,
    "pending_start": 1200,
    "unhcr_assisted_start": 800,
    "decisions_other": 200
  }'
```

### Example Response:

```json
{
  "predicted_acceptance_rate": 0.847,
  "prediction_percentage": "84.70%",
  "confidence": "High",
  "similar_cases_info": {
    "count": 15,
    "avg_acceptance_rate": 0.832,
    "years_available": [2019, 2020, 2021, 2022, 2023]
  }
}
```

## 📱 Mobile App Instructions

### Prerequisites:
- Android Studio (latest version)
- Android device or emulator (API level 21+)
- Internet connection for API calls

### Installation Steps:

1. **Clone the Repository:**
   ```bash
   git clone https:(https://github.com/Irakoze-Hortance/summative-ml/)
   ```


## 🎥 Video Demo

**YouTube Demo Link:** https://youtu.be/XynO-u_P6s0



## 🔧 Technical Stack

- **Backend:** FastAPI, Python, Scikit-learn
- **Frontend:** Flutter
- **ML Model:** Random Forest Regressor
- **Deployment:** Render
- **Data Processing:** Pandas, NumPy

## 📊 Model Performance

- **Primary Model:** Random Forest (RMSE: 0.19)
- **Features:** Country, Origin, Procedure Type, Year, Application Volumes
- **Confidence Levels:** Based on historical data availability
- **Accuracy:** ±19 percentage points average prediction error

