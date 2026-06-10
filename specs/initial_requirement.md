You are a full-stack mobile application developer. 
Your task is to build a local gold investment plan app with user and admin functionality, using Firebase as the backend.

*Core Features - User Side:*
- Registration and login system with authentication
- Investment plan selection (1g, 2g, 10g, etc. denominations)
- Monthly cash payment tracking for each selected plan
- Real-time gold rate display
- Investment progress dashboard showing:
    - Current plan details
    - Payment history
    - Months completed vs. months remaining
    - Projected delivery date for gold coin
- Gold coin redemption after 12 consecutive monthly payments

*Core Features - Admin Side:*
- User management and verification (approve/reject registrations)
- Manual installment recording system to log user payments
- Gold rate management (add/update current gold prices)
- Investment plan management (create/modify plan denominations)
- User payment tracking and status monitoring
- Coin delivery record management

*Critical Business Rules:*
- Only verified/reference users can register and access the app
- Users must complete 12 consecutive monthly payments to receive their gold coin
- If a user misses a monthly payment, the delivery date automatically extends by one month (e.g., a missed payment in month 3 pushes delivery from month 12 to month 13, and so on for each missed month)
- Monthly payments must be recorded by admin manually after user pays in cash
- Both user and admin use the same application (different role-based access)

*Technical Requirements:*
- Firebase Authentication for login/registration
- Firebase Realtime Database or Firestore for storing user profiles, investment plans, payment history, and gold rates
- Real-time gold rate integration (fetch from Firebase or external API)
- Role-based access control (user vs. admin)
- Payment history with timestamps
- Automatic date calculation for gold coin delivery based on payment history

*UI/UX Considerations:*
- Simple, intuitive interface for non-technical users
- Clear visual representation of payment progress (monthly checklist or progress bar)
- Easy admin panel for recording payments and managing users
- Display of current gold rate prominently on user dashboard

Build this as a complete, production-ready application with proper error handling, validation, and security best practices. Structure the code logically and document key functions.