# Atlas Intelligence

Atlas Intelligence is an educational AI tool designed to help users search and interact with educational content.

## Project Structure

- **backend/**: Node.js backend API server
- **ios/**: iOS mobile application
- **docs/**: Project documentation

## Backend

The backend is built with Node.js and Express, providing RESTful API endpoints for the mobile app.

### Prerequisites

- Node.js (v16.0.0 or higher)
- MongoDB

### Setup

1. Navigate to the backend directory:
   ```
   cd backend
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Create a `.env` file based on `.env.example` and fill in your configuration

4. Start the server:
   ```
   npm start
   ```

5. The server will run on http://localhost:5000

## iOS App

The iOS app is built with Swift and uses SwiftUI for the user interface.

### Prerequisites

- Xcode 14.0+
- iOS 15.0+

### Setup

1. Open the project in Xcode:
   ```
   open ios/AtlasAI.xcodeproj
   ```
   (If using CocoaPods, open the .xcworkspace file instead)

2. Build and run the app on your simulator or device

## License

[Add your license here] 