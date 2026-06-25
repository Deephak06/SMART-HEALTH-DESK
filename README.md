# Smart Health Desk

A comprehensive full-stack medical web application for healthcare management, designed for patients and doctors.

## Features

### Authentication & Access Control
- Self-registration for users (Patient or Doctor roles)
- Secure login and logout
- Role-based access control
- Protected routes based on user roles

### Patient Features
- **Health Records Management**: Day-wise tracking of health parameters
  - Blood Pressure (Systolic/Diastolic)
  - Glucose levels (Pre-meal and Post-meal)
  - WBC count
  - Additional notes
- **Medication Management**: View prescribed medications and daily schedules
- **Medication Schedule**: Mark medications as taken with timestamps
- **Notifications**: View in-app notifications and medication reminders
- **Health Dashboard**: Visual overview of latest health metrics

### Doctor Features
- **Patient List**: Browse and search all registered patients
- **Patient Details**: Comprehensive view of patient health history
- **Add Prescriptions**: Prescribe medications with dosage, frequency, and instructions
- **Record Visits**: Document patient visits with symptoms, diagnosis, and observations
- **View Health Records**: Access patient health records
- **Statistics Dashboard**: View total patients, today's visits, and active prescriptions

### Technical Features
- **Notification System**: Framework for SMS, WhatsApp, and in-app notifications
- **Secure Data Storage**: All medical data is protected with Row Level Security
- **Responsive Design**: Mobile-friendly interface with clean white and light blue theme
- **HL7 Ready**: Database structure supports future HL7 integration for hospital systems

## Tech Stack

### Frontend
- React 18
- TypeScript
- Tailwind CSS
- Lucide React (icons)
- Vite (build tool)

### Backend & Database
- Supabase (PostgreSQL)
- Row Level Security (RLS)
- Edge Functions for notifications
- Real-time authentication

## Database Schema

### Core Tables
- `profiles` - User profiles with role information
- `patients` - Patient-specific information
- `doctors` - Doctor-specific information
- `health_records` - Day-wise health parameters
- `medications` - Medication database
- `prescriptions` - Doctor prescriptions for patients
- `medication_schedules` - Daily medication schedules
- `notifications` - Notification and alert logs
- `visits` - Doctor visit records

## Getting Started

### Prerequisites
- Node.js 18+
- npm or yarn
- Supabase account

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```

3. The application is already configured with Supabase

4. Start the development server:
   ```bash
   npm run dev
   ```

5. Build for production:
   ```bash
   npm run build
   ```

## User Roles

### Patient
- Register as a patient
- Add and view health records
- Track medications
- View notifications

### Doctor
- Register as a doctor
- View all patients
- Access patient health history
- Add prescriptions
- Record visit notes

## Security

- All tables use Row Level Security (RLS)
- Patients can only access their own data
- Doctors can access their patients' data
- Admins have full access
- JWT-based authentication
- Secure password handling

## API Integration

### Notification System
The application includes an edge function for sending notifications:
- SMS notifications (ready for integration)
- WhatsApp notifications (ready for integration)
- In-app notifications (fully functional)

## Future Enhancements

- SMS/WhatsApp gateway integration
- HL7 interface for hospital systems
- Automated medication reminders
- Advanced analytics and reporting
- Telemedicine integration
- Mobile applications (iOS/Android)
- Real-time chat between doctors and patients

## License

This is a demonstration project for healthcare management systems.

## Support

For issues or questions, please refer to the documentation or contact support.
