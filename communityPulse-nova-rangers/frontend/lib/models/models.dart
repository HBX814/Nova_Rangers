/// CommunityPulse — Dart Data Models
///
/// These models mirror the Pydantic v2 models on the backend and
/// the Firestore document schemas. They are used for type-safe
/// JSON serialisation/deserialisation in the Flutter app.
///
/// TODO: Generate with freezed + json_serializable:
///   flutter pub run build_runner build --delete-conflicting-outputs
library;

// ---------------------------------------------------------------------------
// Need Category Enum
// ---------------------------------------------------------------------------
enum NeedCategory {
  FLOOD,
  DROUGHT,
  MEDICAL,
  SHELTER,
  EDUCATION,
  FOOD,
  INFRASTRUCTURE,
  WATER,
}

// ---------------------------------------------------------------------------
// Need Status Enum
// ---------------------------------------------------------------------------
enum NeedStatus {
  OPEN,
  IN_PROGRESS,
  RESOLVED,
}

// ---------------------------------------------------------------------------
// Availability Status Enum
// ---------------------------------------------------------------------------
enum AvailabilityStatus {
  AVAILABLE,
  BUSY,
  OFFLINE,
}

// ---------------------------------------------------------------------------
// Assignment Status Enum
// ---------------------------------------------------------------------------
enum AssignmentStatus {
  PENDING,
  ACCEPTED,
  IN_PROGRESS,
  COMPLETED,
}

// ---------------------------------------------------------------------------
// Need Model
// ---------------------------------------------------------------------------
class Need {
  final String needId;
  final NeedCategory needCategory;
  final String title;
  final String description;
  final int urgencyScore;
  final int affectedPopulation;
  final String primaryLocationText;
  final double lat;
  final double lng;
  final double priorityIndex;
  final NeedStatus status;
  final int reportCount;
  final DateTime submittedAt;
  final String orgId;

  Need({
    required this.needId,
    required this.needCategory,
    required this.title,
    required this.description,
    required this.urgencyScore,
    required this.affectedPopulation,
    required this.primaryLocationText,
    required this.lat,
    required this.lng,
    this.priorityIndex = 0.0,
    this.status = NeedStatus.OPEN,
    this.reportCount = 1,
    required this.submittedAt,
    required this.orgId,
  });

  factory Need.fromJson(Map<String, dynamic> json) {
    return Need(
      needId: json['need_id'] as String,
      needCategory: NeedCategory.values.firstWhere(
        (e) => e.name == json['need_category'],
        orElse: () => NeedCategory.FOOD,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      urgencyScore: json['urgency_score'] as int,
      affectedPopulation: json['affected_population'] as int,
      primaryLocationText: json['primary_location_text'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      priorityIndex: (json['priority_index'] as num?)?.toDouble() ?? 0.0,
      status: NeedStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NeedStatus.OPEN,
      ),
      reportCount: json['report_count'] as int? ?? 1,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      orgId: json['org_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'need_id': needId,
        'need_category': needCategory.name,
        'title': title,
        'description': description,
        'urgency_score': urgencyScore,
        'affected_population': affectedPopulation,
        'primary_location_text': primaryLocationText,
        'lat': lat,
        'lng': lng,
        'priority_index': priorityIndex,
        'status': status.name,
        'report_count': reportCount,
        'submitted_at': submittedAt.toIso8601String(),
        'org_id': orgId,
      };
}

// ---------------------------------------------------------------------------
// Volunteer Model
// ---------------------------------------------------------------------------
class Volunteer {
  final String volunteerId;
  final String name;
  final String phone;
  final List<String> skills;
  final double currentLat;
  final double currentLng;
  final AvailabilityStatus availabilityStatus;
  final double performanceScore;
  final int tasksCompleted;
  final String fcmToken;
  final String geohash;
  final List<String> languages;
  final DateTime joinedDate;

  Volunteer({
    required this.volunteerId,
    required this.name,
    required this.phone,
    this.skills = const [],
    required this.currentLat,
    required this.currentLng,
    this.availabilityStatus = AvailabilityStatus.OFFLINE,
    this.performanceScore = 0.0,
    this.tasksCompleted = 0,
    this.fcmToken = '',
    this.geohash = '',
    this.languages = const [],
    required this.joinedDate,
  });

  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      volunteerId: json['volunteer_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      skills: List<String>.from(json['skills'] ?? []),
      currentLat: (json['current_lat'] as num).toDouble(),
      currentLng: (json['current_lng'] as num).toDouble(),
      availabilityStatus: AvailabilityStatus.values.firstWhere(
        (e) => e.name == json['availability_status'],
        orElse: () => AvailabilityStatus.OFFLINE,
      ),
      performanceScore: (json['performance_score'] as num?)?.toDouble() ?? 0.0,
      tasksCompleted: json['tasks_completed'] as int? ?? 0,
      fcmToken: json['fcm_token'] as String? ?? '',
      geohash: json['geohash'] as String? ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      joinedDate: DateTime.parse(json['joined_date'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'volunteer_id': volunteerId,
        'name': name,
        'phone': phone,
        'skills': skills,
        'current_lat': currentLat,
        'current_lng': currentLng,
        'availability_status': availabilityStatus.name,
        'performance_score': performanceScore,
        'tasks_completed': tasksCompleted,
        'fcm_token': fcmToken,
        'geohash': geohash,
        'languages': languages,
        'joined_date': joinedDate.toIso8601String(),
      };
}

// ---------------------------------------------------------------------------
// Assignment Model
// ---------------------------------------------------------------------------
class Assignment {
  final String assignmentId;
  final String needId;
  final String volunteerId;
  final AssignmentStatus status;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final int? ngoSatisfactionRating;

  Assignment({
    required this.assignmentId,
    required this.needId,
    required this.volunteerId,
    this.status = AssignmentStatus.PENDING,
    required this.assignedAt,
    this.acceptedAt,
    this.completedAt,
    this.ngoSatisfactionRating,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      assignmentId: json['assignment_id'] as String,
      needId: json['need_id'] as String,
      volunteerId: json['volunteer_id'] as String,
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AssignmentStatus.PENDING,
      ),
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      ngoSatisfactionRating: json['ngo_satisfaction_rating'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'assignment_id': assignmentId,
        'need_id': needId,
        'volunteer_id': volunteerId,
        'status': status.name,
        'assigned_at': assignedAt.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'ngo_satisfaction_rating': ngoSatisfactionRating,
      };
}

// ---------------------------------------------------------------------------
// Organization Model
// ---------------------------------------------------------------------------
class Organization {
  final String orgId;
  final String name;
  final String description;
  final String contactEmail;
  final String contactPhone;
  final String address;
  final String district;
  final String logoUrl;
  final DateTime createdAt;
  final bool isVerified;

  Organization({
    required this.orgId,
    required this.name,
    this.description = '',
    required this.contactEmail,
    this.contactPhone = '',
    this.address = '',
    this.district = '',
    this.logoUrl = '',
    required this.createdAt,
    this.isVerified = false,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      orgId: json['org_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      contactEmail: json['contact_email'] as String,
      contactPhone: json['contact_phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      district: json['district'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'org_id': orgId,
        'name': name,
        'description': description,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'address': address,
        'district': district,
        'logo_url': logoUrl,
        'created_at': createdAt.toIso8601String(),
        'is_verified': isVerified,
      };
}

// ---------------------------------------------------------------------------
// Submission Payload Model
// ---------------------------------------------------------------------------
class SubmissionPayload {
  final String submissionId;
  final String submittedBy;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String locationText;
  final List<String> mediaUrls;
  final DateTime submittedAt;
  final String? orgId;
  final String? extractedCategory;
  final int? extractedUrgency;
  final bool? isDuplicate;
  final String? duplicateOfNeedId;

  SubmissionPayload({
    this.submissionId = '',
    required this.submittedBy,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    this.locationText = '',
    this.mediaUrls = const [],
    required this.submittedAt,
    this.orgId,
    this.extractedCategory,
    this.extractedUrgency,
    this.isDuplicate,
    this.duplicateOfNeedId,
  });

  factory SubmissionPayload.fromJson(Map<String, dynamic> json) {
    return SubmissionPayload(
      submissionId: json['submission_id'] as String? ?? '',
      submittedBy: json['submitted_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      locationText: json['location_text'] as String? ?? '',
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      orgId: json['org_id'] as String?,
      extractedCategory: json['extracted_category'] as String?,
      extractedUrgency: json['extracted_urgency'] as int?,
      isDuplicate: json['is_duplicate'] as bool?,
      duplicateOfNeedId: json['duplicate_of_need_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'submitted_by': submittedBy,
        'title': title,
        'description': description,
        'lat': lat,
        'lng': lng,
        'location_text': locationText,
        'media_urls': mediaUrls,
        'submitted_at': submittedAt.toIso8601String(),
        'org_id': orgId,
        'extracted_category': extractedCategory,
        'extracted_urgency': extractedUrgency,
        'is_duplicate': isDuplicate,
        'duplicate_of_need_id': duplicateOfNeedId,
      };
}
