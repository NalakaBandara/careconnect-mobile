import 'package:careconnect_mobile/features/find_care/domain/care_professional.dart';

abstract final class FindCarePreviewData {
  static const specialties = [
    'All',
    'General Practice',
    'Cardiology',
    'Dermatology',
    'Paediatrics',
  ];

  static const professionals = [
    CareProfessional(
      id: '1',
      firstName: 'Arun',
      lastName: 'Mehta',
      isVerified: true,
      yearsOfExperience: 12,
      rating: 4.9,
      nextAvailableLabel: 'Today, 4:30 PM',
      bio: 'Experienced in preventive care and long-term condition management.',
      services: [
        CareService(
          id: '1',
          name: 'General consultation',
          description: 'Everyday health concerns and check-ups',
          durationMinutes: 20,
        ),
        CareService(
          id: '2',
          name: 'Chronic care review',
          description: 'Ongoing condition and medication review',
          durationMinutes: 30,
        ),
        CareService(
          id: '3',
          name: 'Preventive screening',
          description: 'Personalised health and risk assessment',
          durationMinutes: 30,
        ),
      ],
      availability: [
        CareAvailabilityPreview(
          day: 'Today',
          date: 'Sep 11',
          isoDate: '2026-09-11',
          times: ['16:30', '17:00'],
        ),
        CareAvailabilityPreview(
          day: 'Tomorrow',
          date: 'Sep 12',
          isoDate: '2026-09-12',
          times: ['09:00', '10:30', '14:00'],
        ),
        CareAvailabilityPreview(
          day: 'Saturday',
          date: 'Sep 13',
          isoDate: '2026-09-13',
          times: ['09:30', '11:00'],
        ),
      ],
      specialties: [CareSpecialty(id: '1', name: 'General Practice')],
      clinics: [
        CareClinicSummary(
          id: '1',
          name: 'Northgate Medical Centre',
          city: 'Colombo 03',
        ),
      ],
    ),
    CareProfessional(
      id: '2',
      firstName: 'Senuri',
      lastName: 'Perera',
      isVerified: true,
      yearsOfExperience: 9,
      rating: 4.8,
      nextAvailableLabel: 'Tomorrow, 9:00 AM',
      bio: 'Focused on heart health, prevention, and patient education.',
      services: [
        CareService(
          id: '4',
          name: 'Cardiology consultation',
          description: 'Assessment and personalised treatment planning',
          durationMinutes: 30,
        ),
        CareService(
          id: '5',
          name: 'Heart health review',
          description: 'Follow-up review and prevention guidance',
          durationMinutes: 20,
        ),
      ],
      availability: [
        CareAvailabilityPreview(
          day: 'Tomorrow',
          date: 'Sep 12',
          isoDate: '2026-09-12',
          times: ['09:00', '11:30'],
        ),
        CareAvailabilityPreview(
          day: 'Monday',
          date: 'Sep 14',
          isoDate: '2026-09-14',
          times: ['13:00', '15:30'],
        ),
      ],
      specialties: [CareSpecialty(id: '2', name: 'Cardiology')],
      clinics: [
        CareClinicSummary(id: '2', name: 'Lakeside Health', city: 'Colombo 05'),
      ],
    ),
    CareProfessional(
      id: '3',
      firstName: 'Maya',
      lastName: 'Fernando',
      isVerified: true,
      yearsOfExperience: 7,
      rating: 4.7,
      nextAvailableLabel: 'Friday, 11:30 AM',
      bio: 'Supporting adults and children with practical skin-care plans.',
      services: [
        CareService(
          id: '6',
          name: 'Skin consultation',
          description: 'Assessment for common skin concerns',
          durationMinutes: 20,
        ),
      ],
      availability: [
        CareAvailabilityPreview(
          day: 'Friday',
          date: 'Sep 18',
          isoDate: '2026-09-18',
          times: ['11:30', '14:30'],
        ),
      ],
      specialties: [CareSpecialty(id: '3', name: 'Dermatology')],
      clinics: [
        CareClinicSummary(
          id: '3',
          name: 'Harbour Wellness Clinic',
          city: 'Galle',
        ),
      ],
    ),
    CareProfessional(
      id: '4',
      firstName: 'Kavindu',
      lastName: 'Jayasinghe',
      isVerified: false,
      yearsOfExperience: 6,
      rating: 4.6,
      nextAvailableLabel: 'Monday, 2:00 PM',
      bio: 'Family-centred care for infants, children, and young people.',
      services: [
        CareService(
          id: '7',
          name: 'Child health visit',
          description: 'Support for children’s health and development',
          durationMinutes: 30,
        ),
      ],
      availability: [
        CareAvailabilityPreview(
          day: 'Monday',
          date: 'Sep 14',
          isoDate: '2026-09-14',
          times: ['14:00', '15:00'],
        ),
      ],
      specialties: [CareSpecialty(id: '4', name: 'Paediatrics')],
      clinics: [
        CareClinicSummary(
          id: '4',
          name: 'Central Children’s Clinic',
          city: 'Kandy',
        ),
      ],
    ),
  ];
}
