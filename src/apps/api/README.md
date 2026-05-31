# HealthPass API

A secure .NET 8 Web API for managing clinical health information with Google token authentication.

## Overview

HealthPass API provides secure endpoints to access clinical user information including medical history, medications, allergies, and vital signs tracking. All endpoints are protected by Google ID token authentication, ensuring only authorized users can access sensitive health data.

## Key Features

✅ **Google OAuth Authentication** - Secure token-based authentication  
✅ **Clinical Data Management** - User profiles, medical conditions, medications  
✅ **Vital Signs Tracking** - Temperature, heart rate, blood pressure, etc.  
✅ **Mock Data Service** - Pre-configured test data for development  
✅ **Swagger Documentation** - Interactive API documentation  
✅ **CORS Support** - Ready for frontend integration

## Getting Started

### Prerequisites

- .NET 8 SDK
- Google Cloud Platform account
- OAuth 2.0 Client ID from Google

### Setup Steps

1. **Configure Google OAuth**

   ```bash
   cd HealthPassAPI
   dotnet user-secrets init
   dotnet user-secrets set "Authentication:Google:ClientId" "YOUR_CLIENT_ID"
   ```

2. **Run the API**

   ```bash
   dotnet run
   ```

3. **Access Swagger UI**
   - HTTP: http://localhost:5186/swagger
   - HTTPS: https://localhost:7183/swagger

## API Endpoints

All endpoints require `Authorization: Bearer {google-id-token}` header.

### Clinical User Endpoints

```
GET /api/clinicaluser/{userId}
```

Retrieves complete clinical profile including medical history, medications, and allergies.

```
GET /api/clinicaluser/{userId}/vitals/latest
```

Returns the most recent vital signs measurement.

```
GET /api/clinicaluser/{userId}/vitals/history?days={days}
```

Returns vital signs history for specified number of days (1-365).

## Mock Test Data

Three test users are available:

- **user001** (John Doe) - Type 2 Diabetes, Hypertension
- **user002** (Jane Smith) - Asthma
- **user003** (Robert Johnson) - No conditions

## Documentation

- **[README.md](HealthPassAPI/README.md)** - Complete documentation
- **[QUICKSTART.md](HealthPassAPI/QUICKSTART.md)** - Quick reference guide
- **[TESTING.md](HealthPassAPI/TESTING.md)** - Testing instructions
- **[Postman Collection](HealthPassAPI/HealthPassAPI.postman_collection.json)** - API testing collection

## Project Structure

```
HealthPassAPI/
├── Controllers/
│   └── ClinicalUserController.cs       # API endpoints
├── Models/
│   ├── ClinicalUser.cs                 # User data model
│   └── VitalSigns.cs                   # Vital signs model
├── Services/
│   ├── IMockDataService.cs             # Service interface
│   └── MockDataService.cs              # Mock data implementation
├── Authentication/
│   └── GoogleTokenValidator.cs         # Google token validation
├── Program.cs                          # App configuration
├── appsettings.json                    # Configuration
└── .env.template                       # Environment variables template
```

## Authentication Flow

1. Client authenticates with Google (via web/mobile app)
2. Client receives Google ID token
3. Client includes token in API requests: `Authorization: Bearer {token}`
4. API validates token with Google servers
5. API processes request if token is valid
6. API returns 401 if token is invalid/missing

## Example Usage

### Get Clinical User

```bash
curl -X GET "http://localhost:5186/api/clinicaluser/user001" \
  -H "Authorization: Bearer YOUR_GOOGLE_ID_TOKEN"
```

**Response:**

```json
{
  "userId": "user001",
  "email": "john.doe@example.com",
  "fullName": "John Doe",
  "dateOfBirth": "1985-06-15",
  "bloodType": "A+",
  "allergies": ["Penicillin", "Peanuts"],
  "medicalConditions": [
    {
      "conditionName": "Type 2 Diabetes",
      "diagnosedDate": "2018-03-10",
      "severity": "Moderate"
    }
  ],
  "currentMedications": [
    {
      "medicationName": "Metformin",
      "dosage": "500mg",
      "frequency": "Twice daily"
    }
  ]
}
```

## Security Considerations

- ✅ All endpoints require valid Google ID token
- ✅ Tokens are validated against Google's public keys
- ✅ Token expiration is enforced (1-hour lifetime)
- ⚠️ Configure CORS for specific domains in production
- ⚠️ Use HTTPS in production
- ⚠️ Never commit Client ID to version control

## Development

### Build

```bash
dotnet build
```

### Run

```bash
dotnet run
```

### Test

```bash
dotnet test
```

## Integration with Flutter App

The API is designed to work seamlessly with the Flutter health_pass app in this workspace:

```dart
// Flutter integration example
final GoogleSignInAuthentication auth = await googleUser.authentication;
final response = await http.get(
  Uri.parse('http://your-api-url/api/clinicaluser/user001'),
  headers: {
    'Authorization': 'Bearer ${auth.idToken}',
  },
);
```

## Next Steps

- [ ] Replace mock service with Entity Framework + SQL Server
- [ ] Add create/update/delete operations
- [ ] Implement user-specific data filtering based on token claims
- [ ] Add comprehensive logging and monitoring
- [ ] Implement API rate limiting
- [ ] Add API versioning
- [ ] Set up CI/CD pipeline
- [ ] Deploy to Azure/AWS

## Support

For issues or questions:

1. Check the documentation files
2. Review Swagger UI for endpoint details
3. Verify Google OAuth configuration
4. Check application logs

## License

Part of the HealthPass project.
