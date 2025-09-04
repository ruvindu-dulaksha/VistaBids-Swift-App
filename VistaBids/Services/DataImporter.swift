import Foundation
import FirebaseFirestore

class DataImporter {
    private let db = Firestore.firestore()
    
    func importSampleProperties() {
        // Sample properties data
        let propertiesArray: [[String: Any]] = [
            [
                "id": "prop_001",
                "title": "Modern Villa with Ocean View",
                "description": "Stunning 4-bedroom villa with panoramic ocean views, modern amenities, and private pool. Located in the prestigious Galle Face area with easy access to Colombo city center.",
                "price": 45000000,
                "location": "Galle Face, Colombo 03",
                "latitude": 6.9271,
                "longitude": 79.8612,
                "bedrooms": 4,
                "bathrooms": 3,
                "area": 3500,
                "propertyType": "Villa",
                "images": [
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
                    "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800"
                ],
                "sellerName": "Kamal Perera",
                "sellerPhone": "+94771234567",
                "sellerEmail": "kamal.perera@email.com",
                "createdAt": "2025-08-10T10:30:00Z",
                "status": "available"
            ],
            [
                "id": "prop_002",
                "title": "Luxury Apartment in Kiribathgoda",
                "description": "Brand new 3-bedroom luxury apartment with modern kitchen, balcony garden, and 24/7 security. Perfect for families looking for comfort and convenience.",
                "price": 18500000,
                "location": "Kiribathgoda",
                "latitude": 6.9804,
                "longitude": 79.9297,
                "bedrooms": 3,
                "bathrooms": 2,
                "area": 1800,
                "propertyType": "Apartment",
                "images": [
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800",
                    "https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?w=800"
                ],
                "sellerName": "Nimal Silva",
                "sellerPhone": "+94712345678",
                "sellerEmail": "nimal.silva@email.com",
                "createdAt": "2025-08-12T14:15:00Z",
                "status": "available"
            ],
            [
                "id": "prop_003",
                "title": "Traditional House in Kandy",
                "description": "Beautiful traditional Sri Lankan house with wooden architecture, large garden, and mountain views. Perfect for those who love heritage and nature.",
                "price": 12750000,
                "location": "Kandy City",
                "latitude": 7.2906,
                "longitude": 80.6337,
                "bedrooms": 5,
                "bathrooms": 2,
                "area": 2800,
                "propertyType": "House",
                "images": [
                    "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800",
                    "https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800",
                    "https://images.unsplash.com/photo-1585128792020-803d29415281?w=800"
                ],
                "sellerName": "Sumith Bandara",
                "sellerPhone": "+94723456789",
                "sellerEmail": "sumith.bandara@email.com",
                "createdAt": "2025-08-11T09:45:00Z",
                "status": "available"
            ],
            [
                "id": "prop_004",
                "title": "Beach Front Land in Negombo",
                "description": "Prime beachfront land perfect for hotel or resort development. Direct beach access with 100m of pristine coastline. Excellent investment opportunity.",
                "price": 75000000,
                "location": "Negombo Beach",
                "latitude": 7.2084,
                "longitude": 79.8385,
                "bedrooms": 0,
                "bathrooms": 0,
                "area": 5000,
                "propertyType": "Land",
                "images": [
                    "https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800",
                    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
                    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800"
                ],
                "sellerName": "Ravi Fernando",
                "sellerPhone": "+94734567890",
                "sellerEmail": "ravi.fernando@email.com",
                "createdAt": "2025-08-09T16:20:00Z",
                "status": "available"
            ],
            [
                "id": "prop_005",
                "title": "Modern Condo in Nugegoda",
                "description": "Stylish 2-bedroom condominium with gym, swimming pool, and rooftop garden. Walking distance to Nugegoda town and public transport.",
                "price": 15200000,
                "location": "Nugegoda",
                "latitude": 6.8649,
                "longitude": 79.8997,
                "bedrooms": 2,
                "bathrooms": 2,
                "area": 1200,
                "propertyType": "Condominium",
                "images": [
                    "https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800",
                    "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
                    "https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800"
                ],
                "sellerName": "Chamari Jayasinghe",
                "sellerPhone": "+94745678901",
                "sellerEmail": "chamari.jay@email.com",
                "createdAt": "2025-08-13T11:30:00Z",
                "status": "available"
            ],
            [
                "id": "prop_006",
                "title": "Commercial Building in Maharagama",
                "description": "3-story commercial building suitable for offices or retail. Prime location with high foot traffic and ample parking space.",
                "price": 32500000,
                "location": "Maharagama",
                "latitude": 6.8480,
                "longitude": 79.9267,
                "bedrooms": 0,
                "bathrooms": 6,
                "area": 4200,
                "propertyType": "Commercial",
                "images": [
                    "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800",
                    "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800",
                    "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800"
                ],
                "sellerName": "Sunil Wickramasinghe",
                "sellerPhone": "+94756789012",
                "sellerEmail": "sunil.wickrama@email.com",
                "createdAt": "2025-08-08T13:45:00Z",
                "status": "available"
            ],
            [
                "id": "prop_007",
                "title": "Garden House in Matara",
                "description": "Charming house with extensive gardens, fruit trees, and peaceful surroundings. Perfect for retirement or weekend getaway.",
                "price": 8750000,
                "location": "Matara",
                "latitude": 5.9549,
                "longitude": 80.5550,
                "bedrooms": 3,
                "bathrooms": 2,
                "area": 2200,
                "propertyType": "House",
                "images": [
                    "https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=800",
                    "https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=800",
                    "https://images.unsplash.com/photo-1520637836862-4d197d17c25a?w=800"
                ],
                "sellerName": "Priyanka Rathnayake",
                "sellerPhone": "+94767890123",
                "sellerEmail": "priyanka.rathna@email.com",
                "createdAt": "2025-08-14T08:20:00Z",
                "status": "available"
            ],
            [
                "id": "prop_008",
                "title": "Penthouse in Colombo 07",
                "description": "Luxurious penthouse with 360-degree city views, private elevator, and rooftop terrace. Premium location in Cinnamon Gardens.",
                "price": 95000000,
                "location": "Cinnamon Gardens, Colombo 07",
                "latitude": 6.9147,
                "longitude": 79.8757,
                "bedrooms": 4,
                "bathrooms": 4,
                "area": 4800,
                "propertyType": "Penthouse",
                "images": [
                    "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800",
                    "https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=800",
                    "https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=800"
                ],
                "sellerName": "Dilshan Rajapaksa",
                "sellerPhone": "+94778901234",
                "sellerEmail": "dilshan.raja@email.com",
                "createdAt": "2025-08-07T15:10:00Z",
                "status": "available"
            ],
            [
                "id": "prop_009",
                "title": "Farmland in Anuradhapura",
                "description": "40 acres of fertile agricultural land with irrigation facilities, perfect for cultivation or agro-tourism development.",
                "price": 22000000,
                "location": "Anuradhapura",
                "latitude": 8.3114,
                "longitude": 80.4037,
                "bedrooms": 0,
                "bathrooms": 0,
                "area": 161874,
                "propertyType": "Agricultural",
                "images": [
                    "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800",
                    "https://images.unsplash.com/photo-1464822759844-d150ad6d1c71?w=800",
                    "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800"
                ],
                "sellerName": "Janaka Gunawardena",
                "sellerPhone": "+94789012345",
                "sellerEmail": "janaka.guna@email.com",
                "createdAt": "2025-08-06T12:00:00Z",
                "status": "available"
            ],
            [
                "id": "prop_010",
                "title": "Studio Apartment in Mount Lavinia",
                "description": "Cozy studio apartment near the beach, perfect for young professionals or students. Fully furnished with modern amenities.",
                "price": 6500000,
                "location": "Mount Lavinia",
                "latitude": 6.8344,
                "longitude": 79.8643,
                "bedrooms": 1,
                "bathrooms": 1,
                "area": 650,
                "propertyType": "Studio",
                "images": [
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
                    "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800",
                    "https://images.unsplash.com/photo-1571055107559-3e67626fa8be?w=800"
                ],
                "sellerName": "Sachi Mendis",
                "sellerPhone": "+94790123456",
                "sellerEmail": "sachi.mendis@email.com",
                "createdAt": "2025-08-14T07:30:00Z",
                "status": "available"
            ]
        ]
        
        let batch = db.batch()
        let collection = db.collection("sale_properties")
        
        for propertyData in propertiesArray {
            let docRef = collection.document()
            
            // Convert the JSON data to match our SaleProperty Firestore structure
            var firestoreData: [String: Any] = [:]
            
            // Basic property info
            firestoreData["id"] = propertyData["id"]
            firestoreData["title"] = propertyData["title"]
            firestoreData["description"] = propertyData["description"]
            firestoreData["price"] = propertyData["price"]
            firestoreData["bedrooms"] = propertyData["bedrooms"]
            firestoreData["bathrooms"] = propertyData["bathrooms"]
            firestoreData["area"] = "\(propertyData["area"] ?? 0) sq ft" // Convert Int to String format
            firestoreData["propertyType"] = propertyData["propertyType"]
            firestoreData["images"] = propertyData["images"]
            firestoreData["status"] = "active" // Use SalePropertyStatus values
            firestoreData["isNew"] = true
            
            // Convert date strings to Firestore timestamps
            if let createdAtString = propertyData["createdAt"] as? String {
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: createdAtString) {
                    firestoreData["createdAt"] = Timestamp(date: date)
                    firestoreData["updatedAt"] = Timestamp(date: date)
                    firestoreData["availableFrom"] = Timestamp(date: date)
                }
            }
            
            // Structure seller data to match PropertySeller model
            firestoreData["seller"] = [
                "id": "seller_\(propertyData["id"] ?? "")",
                "name": propertyData["sellerName"] ?? "",
                "email": propertyData["sellerEmail"] ?? "",
                "phone": propertyData["sellerPhone"] ?? "",
                "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
                "rating": 4.5,
                "totalSales": Int.random(in: 1...20),
                "verificationStatus": "verified"
            ]
            
            // Structure address data to match PropertyAddress model
            firestoreData["address"] = [
                "street": "Street Address",
                "city": propertyData["location"] ?? "",
                "state": "Western Province",
                "zipCode": "10000",
                "country": "Sri Lanka"
            ]
            
            // Structure coordinates to match PropertyCoordinates model
            firestoreData["coordinates"] = [
                "latitude": propertyData["latitude"] ?? 0.0,
                "longitude": propertyData["longitude"] ?? 0.0
            ]
            
            // Structure features to match PropertyFeature model array
            let featuresArray = [
                [
                    "id": "f1",
                    "name": "Modern Kitchen",
                    "icon": "oven.fill",
                    "category": "interior"
                ],
                [
                    "id": "f2", 
                    "name": "Swimming Pool",
                    "icon": "figure.pool.swim",
                    "category": "exterior"
                ],
                [
                    "id": "f3",
                    "name": "Garden",
                    "icon": "leaf.fill",
                    "category": "exterior"
                ],
                [
                    "id": "f4",
                    "name": "Parking",
                    "icon": "car.garage",
                    "category": "exterior"
                ]
            ]
            firestoreData["features"] = featuresArray
            
            batch.setData(firestoreData, forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error importing sample data: \(error)")
            } else {
                print("Successfully imported \(propertiesArray.count) sample properties")
            }
        }
    }
}
