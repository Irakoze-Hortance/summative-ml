from fastapi import FastAPI
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
import joblib
import numpy as np
import uvicorn
import pickle
from sklearn.preprocessing import LabelEncoder


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = joblib.load("best_model.pkl")
scaler = joblib.load("scaler.pkl")
label_encoders = joblib.load("LabelEncoder.pkl")
feature_columns = joblib.load("feature_columns.pkl")

class PredictionInput(BaseModel):
    country: str = Field(..., description="Country / territory of asylum/residence")
    origin: str = Field(..., description="Country of origin of asylum seeker")
    procedure_type: str = Field(..., description="RSD procedure type / level")
    year: int = Field(..., ge=2000, le=2030, description="Year of application")
    applied_during_year: int = Field(..., ge=0, description="Number of applications during year")
    pending_start: int = Field(..., ge=0, description="Total pending start-year")
    unhcr_assisted_start: int = Field(..., ge=0, description="UNHCR-assisted at start-year")
    decisions_other: int = Field(..., ge=0, description="Other decisions made")

@app.post("/predict")
def predict_acceptance_rate(input_data: PredictionInput):
    try:
        with open('LabelEncoder.pkl', 'rb') as f:
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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
