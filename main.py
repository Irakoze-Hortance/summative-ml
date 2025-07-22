from fastapi import FastAPI
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
import joblib
import numpy as np
import uvicorn
import pickle
import pandas as pd

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load your trained models and encoders
model = joblib.load("best_model.pkl")
scaler = joblib.load("scaler.pkl")
label_encoders = joblib.load("label_encoders.pkl")
feature_columns = joblib.load("feature_columns.pkl")

# Try to load your training data to get historical statistics
try:
    # Assuming you have your training data saved as a CSV or pickle file
    training_data = pd.read_csv("training_data.csv")  # Replace with your actual training data file
except:
    training_data = None

class PredictionInput(BaseModel):
    country: str = Field(..., description="Country / territory of asylum/residence")
    origin: str = Field(..., description="Country of origin of asylum seeker")
    procedure_type: str = Field(..., description="RSD procedure type / level")
    year: int = Field(..., ge=2000, le=2030, description="Year of application")
    applied_during_year: int = Field(..., ge=0, description="Number of applications during year")
    pending_start: int = Field(..., ge=0, description="Total pending start-year")
    unhcr_assisted_start: int = Field(..., ge=0, description="UNHCR-assisted at start-year")
    decisions_other: int = Field(..., ge=0, description="Other decisions made")

class HistoricalDataRequest(BaseModel):
    country: str = Field(..., description="Country / territory of asylum/residence")
    origin: str = Field(..., description="Country of origin of asylum seeker")
    year: int = Field(..., ge=2000, le=2030, description="Year of application")

@app.post("/historical-data")
def get_historical_data(request: HistoricalDataRequest):
    try:
        if training_data is not None:
            # Filter data based on country, origin, and year
            filtered_data = training_data[
                (training_data['country'] == request.country) &
                (training_data['origin'] == request.origin) &
                (training_data['year'] == request.year)
            ]
            
            if not filtered_data.empty:
                # Get the first matching record or aggregate if multiple records
                if len(filtered_data) == 1:
                    record = filtered_data.iloc[0]
                else:
                    # If multiple records, take the mean/median or most recent
                    record = filtered_data.iloc[-1]  # Take most recent
                
                return {
                    "success": True,
                    "data": {
                        "applied_during_year": int(record.get('applied_during_year', 0)),
                        "pending_start": int(record.get('pending_start', 0)),
                        "unhcr_assisted_start": int(record.get('unhcr_assisted_start', 0)),
                        "decisions_other": int(record.get('decisions_other', 0))
                    }
                }
            else:
                # Try to find data for the same country and origin but different year
                similar_data = training_data[
                    (training_data['country'] == request.country) &
                    (training_data['origin'] == request.origin)
                ]
                
                if not similar_data.empty:
                    # Find closest year
                    similar_data['year_diff'] = abs(similar_data['year'] - request.year)
                    closest_record = similar_data.loc[similar_data['year_diff'].idxmin()]
                    
                    return {
                        "success": True,
                        "data": {
                            "applied_during_year": int(closest_record.get('applied_during_year', 0)),
                            "pending_start": int(closest_record.get('pending_start', 0)),
                            "unhcr_assisted_start": int(closest_record.get('unhcr_assisted_start', 0)),
                            "decisions_other": int(closest_record.get('decisions_other', 0))
                        },
                        "note": f"Data from closest available year: {closest_record['year']}"
                    }
        
        # If no training data or no matches found, return error
        return {
            "success": False,
            "error": "No historical data found for the specified criteria",
            "data": None
        }
    
    except Exception as e:
        return {
            "success": False,
            "error": f"Error retrieving historical data: {str(e)}",
            "data": None
        }

@app.post("/predict")
def predict_acceptance_rate(input_data: PredictionInput):
    try:
        with open('label_encoders.pkl', 'rb') as f:
            label_encoders = pickle.load(f)
        
        country_encoded = 0
        origin_encoded = 0
        procedure_encoded = 0
        
        try:
            if 'country' in label_encoders:
                country_encoded = label_encoders['country'].transform([input_data.country])[0]
        except:
            country_encoded = 0
        
        try:
            if 'origin' in label_encoders:
                origin_encoded = label_encoders['origin'].transform([input_data.origin])[0]
        except:
            origin_encoded = 0
        
        try:
            if 'procedure' in label_encoders:
                procedure_encoded = label_encoders['procedure'].transform([input_data.procedure_type])[0]
        except:
            procedure_encoded = 0
        
        features_array = np.array([[
            country_encoded,
            origin_encoded, 
            procedure_encoded,
            input_data.year,
            input_data.applied_during_year,
            input_data.pending_start,
            input_data.unhcr_assisted_start,
            input_data.decisions_other
        ]])
        
        features_scaled = scaler.transform(features_array)
        
        prediction = model.predict(features_scaled)[0]
        
        prediction = float(max(0.0, min(1.0, prediction)))
        
        return {
            "predicted_acceptance_rate": prediction,
            "prediction_percentage": f"{prediction * 100:.2f}%"
        }
    
    except Exception as e:
        return {"error": f"Prediction failed: {str(e)}"}

@app.get("/")
def read_root():
    return {"message": "Refugee Acceptance Predictor API", "endpoints": ["/predict", "/historical-data"]}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)