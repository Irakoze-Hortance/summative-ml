from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware
import joblib
import numpy as np
import uvicorn
import pickle
import pandas as pd
from sklearn.preprocessing import LabelEncoder
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model components
try:
    model = joblib.load("best_model.pkl")
    scaler = joblib.load("scaler.pkl")
    label_encoders = joblib.load("label_encoders.pkl")
    feature_columns = joblib.load("feature_columns.pkl")
    logger.info("Model components loaded successfully")
except Exception as e:
    logger.error(f"Error loading model components: {e}")
    model = scaler = label_encoders = feature_columns = None

# Load training data
try:
    training_data = pd.read_csv("training_data.csv")
    logger.info(f"Training data loaded: {len(training_data)} records")
except Exception as e:
    logger.warning(f"Could not load training data: {e}")
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

def handle_unknown_category(encoder, value, category_name):
    """
    Handle unknown categories by either adding them to the encoder or using a fallback strategy
    """
    try:
        # Try to transform the value
        return encoder.transform([value])[0]
    except ValueError:
        # Value not seen during training
        logger.warning(f"Unknown {category_name}: '{value}' not in training data")
        
        # Strategy 1: Add the unknown category to the encoder
        # This expands the encoder's classes but may not work well with the trained model
        try:
            # Get current classes
            current_classes = encoder.classes_.tolist()
            
            # Add the new category
            new_classes = current_classes + [value]
            encoder.classes_ = np.array(new_classes)
            
            # Transform with the expanded encoder
            encoded_value = encoder.transform([value])[0]
            logger.info(f"Added new {category_name} '{value}' to encoder with value {encoded_value}")
            return encoded_value
            
        except Exception as e:
            logger.error(f"Could not add new category to encoder: {e}")
            
            # Strategy 2: Use most frequent category as fallback
            if training_data is not None:
                try:
                    if category_name == 'country':
                        most_frequent = training_data['country'].mode()[0]
                    elif category_name == 'origin':
                        most_frequent = training_data['origin'].mode()[0]
                    elif category_name == 'procedure':
                        most_frequent = training_data['procedure_type'].mode()[0]
                    else:
                        most_frequent = current_classes[0]
                    
                    fallback_value = encoder.transform([most_frequent])[0]
                    logger.info(f"Using most frequent {category_name} '{most_frequent}' as fallback (value: {fallback_value})")
                    return fallback_value
                except:
                    pass
            
            # Strategy 3: Use the first class as ultimate fallback
            fallback_value = 0
            logger.info(f"Using default fallback value {fallback_value} for {category_name}")
            return fallback_value

def get_similar_cases(input_data):
    """
    Find similar cases in training data for better prediction context
    """
    if training_data is None:
        return None
    
    # Find cases with same country and origin
    similar_cases = training_data[
        (training_data['country'] == input_data.country) &
        (training_data['origin'] == input_data.origin)
    ]
    
    if len(similar_cases) > 0:
        return {
            "count": len(similar_cases),
            "avg_acceptance_rate": similar_cases.get('acceptance_rate', pd.Series()).mean() if 'acceptance_rate' in similar_cases.columns else None,
            "years_available": sorted(similar_cases['year'].unique().tolist()) if 'year' in similar_cases.columns else []
        }
    
    return None

@app.post("/historical-data")
def get_historical_data(request: HistoricalDataRequest):
    try:
        if training_data is not None:
            filtered_data = training_data[
                (training_data['country'] == request.country) &
                (training_data['origin'] == request.origin) &
                (training_data['year'] == request.year)
            ]
            
            if not filtered_data.empty:
                if len(filtered_data) == 1:
                    record = filtered_data.iloc[0]
                else:
                    record = filtered_data.iloc[-1]  
                
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
                similar_data = training_data[
                    (training_data['country'] == request.country) &
                    (training_data['origin'] == request.origin)
                ]
                
                if not similar_data.empty:
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
        if model is None or scaler is None or label_encoders is None:
            raise HTTPException(status_code=500, detail="Model components not properly loaded")
        
        # Handle categorical encoding with unknown category management
        country_encoded = handle_unknown_category(
            label_encoders.get('country', LabelEncoder()), 
            input_data.country, 
            'country'
        )
        
        origin_encoded = handle_unknown_category(
            label_encoders.get('origin', LabelEncoder()), 
            input_data.origin, 
            'origin'
        )
        
        procedure_encoded = handle_unknown_category(
            label_encoders.get('procedure', LabelEncoder()), 
            input_data.procedure_type, 
            'procedure'
        )
        
        # Create feature array
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
        
        # Scale features
        features_scaled = scaler.transform(features_array)
        
        # Make prediction
        prediction = model.predict(features_scaled)[0]
        
        # Ensure prediction is within valid range
        prediction = float(max(0.0, min(1.0, prediction)))
        
        # Get confidence information from similar cases
        similar_cases = get_similar_cases(input_data)
        
        # Prepare response
        response = {
            "predicted_acceptance_rate": prediction,
            "prediction_percentage": f"{prediction * 100:.2f}%",
            "encoded_features": {
                "country_encoded": int(country_encoded),
                "origin_encoded": int(origin_encoded),
                "procedure_encoded": int(procedure_encoded)
            }
        }
        
        # Add similar cases information if available
        if similar_cases:
            response["similar_cases_info"] = similar_cases
            
            # Add confidence indicator based on historical data availability
            if similar_cases["count"] > 5:
                response["confidence"] = "High"
            elif similar_cases["count"] > 0:
                response["confidence"] = "Medium"
            else:
                response["confidence"] = "Low"
        else:
            response["confidence"] = "Low"
            response["note"] = "No similar historical cases found. Prediction based on general model patterns."
        
        return response
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/model-info")
def get_model_info():
    """Get information about the loaded model and available categories"""
    try:
        info = {
            "model_loaded": model is not None,
            "scaler_loaded": scaler is not None,
            "label_encoders_loaded": label_encoders is not None,
            "training_data_loaded": training_data is not None
        }
        
        if label_encoders:
            info["available_categories"] = {}
            for category, encoder in label_encoders.items():
                info["available_categories"][category] = encoder.classes_.tolist()
        
        if training_data is not None:
            info["training_data_stats"] = {
                "total_records": len(training_data),
                "unique_countries": training_data['country'].nunique() if 'country' in training_data.columns else 0,
                "unique_origins": training_data['origin'].nunique() if 'origin' in training_data.columns else 0,
                "year_range": [int(training_data['year'].min()), int(training_data['year'].max())] if 'year' in training_data.columns else []
            }
        
        return info
    
    except Exception as e:
        return {"error": f"Could not retrieve model info: {str(e)}"}

@app.get("/")
def read_root():
    return {
        "message": "Enhanced Refugee Acceptance Predictor API", 
        "endpoints": ["/predict", "/historical-data", "/model-info"],
        "features": [
            "Handles unknown categories gracefully",
            "Provides confidence indicators",
            "Includes similar cases analysis",
            "Enhanced error handling and logging"
        ]
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)