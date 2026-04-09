import math

def compute_priority_score(urgency_score: float, report_count: int, affected_population: int, nearby_unresolved: int) -> float:
    """
    Computes a priority score between 0 and 1 using the provided formula based on 
    urgency, report count, affected population, and surrounding density.
    """
    density_penalty = math.log(nearby_unresolved + 1) * 0.10
    score = (urgency_score / 10) * 0.35 + math.log(report_count + 1) * 0.20 + math.log(affected_population + 1) * 0.25 - density_penalty
    return round(min(score, 1.0), 4)

def get_nearby_unresolved_count(lat: float, lng: float, db) -> int:
    """
    Queries Firestore for OPEN needs and counts those within approximately 5km 
    (0.045 degrees lat/lng) of the target coordinates.
    """
    count = 0
    # Query needs collection where status is OPEN
    open_needs = db.collection('needs').where('status', '==', 'OPEN').stream()
    
    for need in open_needs:
        data = need.to_dict()
        if not data:
            continue
            
        # Safely extract latitude and longitude
        need_lat = data.get('latitude')
        need_lng = data.get('longitude')
        
        # Check if coordinates are present
        if need_lat is not None and need_lng is not None:
            try:
                # Calculate absolute differences to check the 0.045 degrees boundary
                if abs(float(need_lat) - lat) <= 0.045 and abs(float(need_lng) - lng) <= 0.045:
                    count += 1
            except (ValueError, TypeError):
                # Ignore documents with invalid coordinate formats
                continue
                
    return count
