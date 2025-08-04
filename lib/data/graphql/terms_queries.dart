/// GraphQL queries for Terms and CourseGroups
/// Based on UKCPA-Website GraphQL schema

/// Fragment for Holiday data within Terms
const String holidayFragment = '''
  fragment HolidayFragment on Holiday {
    name
    startDateTime
    endDateTime
  }
''';

/// Fragment for ImagePosition data
const String imagePositionFragment = '''
  fragment ImagePositionFragment on ImagePosition {
    X
    Y
  }
''';

/// Fragment for Studio Course data
const String studioCourseFragment = '''
  fragment StudioCourseFragment on StudioCourse {
    id
    name
    subtitle
    ageFrom
    ageTo
    active
    level
    price
    originalPrice
    currentPrice
    depositPrice
    fullyBooked
    thumbImage
    image
    imagePosition {
      ...ImagePositionFragment
    }
    shortDescription
    description
    attendanceTypes
    startDateTime
    endDateTime
    weeks
    order
    listStyle
    days
    location
    danceType
    videos {
      id
      name
      description
      url
      provider
      thumbnailUrl
      duration
    }
    hasTasterClasses
    tasterPrice
    isAcceptingDeposits
    instructions
    address {
      line1
      line2
      postCode
      city
      county
      country
    }
    displayStatus
    studioInstructions
    equipment
    parkingInfo
    accessibilityInfo
  }
''';

/// Fragment for Online Course data
const String onlineCourseFragment = '''
  fragment OnlineCourseFragment on OnlineCourse {
    id
    name
    subtitle
    ageFrom
    ageTo
    active
    level
    price
    originalPrice
    currentPrice
    depositPrice
    fullyBooked
    thumbImage
    image
    imagePosition {
      ...ImagePositionFragment
    }
    shortDescription
    description
    attendanceTypes
    startDateTime
    endDateTime
    weeks
    order
    listStyle
    days
    location
    danceType
    videos {
      id
      name
      description
      url
      provider
      thumbnailUrl
      duration
    }
    hasTasterClasses
    tasterPrice
    isAcceptingDeposits
    instructions
    displayStatus
    zoomMeeting {
      meetingId
      password
      joinUrl
    }
    requiresEnrollment
    technicalRequirements
    platformInstructions
    recordingUrls
  }
''';

/// Fragment for CourseGroup data - matches CourseGroupFragment exactly
const String courseGroupFragment = '''
  fragment CourseGroupFragment on CourseGroup {
    id
    name
    thumbImage
    image
    imagePosition {
      ...ImagePositionFragment
    }
    shortDescription
    description
    minOriginalPrice
    maxOriginalPrice
    minPrice
    maxPrice
    attendanceTypes
    locations
    danceType
    courseTypes
    courses {
      __typename
      ... on StudioCourse {
        ...StudioCourseFragment
      }
      ... on OnlineCourse {
        ...OnlineCourseFragment
      }
    }
  }
''';

/// Fragment for Term data - matches TermFragment exactly
const String termFragment = '''
  fragment TermFragment on Term {
    id
    name
    endDate
    startDate
    holidays {
      ...HolidayFragment
    }
    courseGroups {
      ...CourseGroupFragment
    }
  }
''';

/// Complete query for fetching terms - matches GetTerms exactly
const String getTermsQuery = '''
  $holidayFragment
  $imagePositionFragment
  $studioCourseFragment
  $onlineCourseFragment
  $courseGroupFragment
  $termFragment
  
  query GetTerms(\$data: TermInput!) {
    getTerms(data: \$data) {
      terms {
        ...TermFragment
      }
      term {
        ...TermFragment
      }
    }
  }
''';

/// Query for fetching a specific course group - matches GetCourseGroup exactly
const String getCourseGroupQuery = '''
  $imagePositionFragment
  $studioCourseFragment
  $onlineCourseFragment
  $courseGroupFragment
  
  query GetCourseGroup(\$id: Float!, \$displayStatus: DisplayStatus) {
    getCourseGroup(id: \$id, displayStatus: \$displayStatus) {
      ...CourseGroupFragment
    }
  }
''';

/// Input types for GraphQL variables
class TermInput {
  final String displayStatus;
  
  const TermInput({required this.displayStatus});
  
  Map<String, dynamic> toJson() => {
    'displayStatus': displayStatus,
  };
}

/// Display status enum values - must match server enum
class DisplayStatus {
  static const String draft = 'DRAFT';
  static const String live = 'LIVE';
  static const String published = 'PUBLISHED';
  static const String archived = 'ARCHIVED';
}