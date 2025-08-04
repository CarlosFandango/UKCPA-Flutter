/// GraphQL queries for Terms and CourseGroups
/// Based on UKCPA-Website GraphQL schema


/// Fragment for Position data (used for image positioning)
const String positionFragment = '''
  fragment PositionFragment on Position {
    X
    Y
  }
''';

/// Fragment for Studio Course data - matches website exactly
const String studioCourseFragment = '''
  fragment StudioCourseFragment on StudioCourse {
    id
    name
    subtitle
    courseGroup {
      id
      name
    }
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
      ...PositionFragment
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
    }
    hasTasterClasses
    tasterPrice
    isAcceptingDeposits
    futureCourseSessions {
      id
      startDateTime
      endDateTime
    }
    sessions {
      id
      startDateTime
      endDateTime
    }
    instructions
    address {
      line1
      line2
      postCode
      city
      county
    }
  }
''';

/// Fragment for Online Course data - matches website exactly
const String onlineCourseFragment = '''
  fragment OnlineCourseFragment on OnlineCourse {
    id
    name
    subtitle
    courseGroup {
      id
      name
    }
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
      ...PositionFragment
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
    hasTasterClasses
    isAcceptingDeposits
    danceType
    location
    tasterPrice
    futureCourseSessions {
      id
      startDateTime
      endDateTime
    }
    sessions {
      id
      startDateTime
      endDateTime
    }
    videos {
      id
      name
      description
      url
      provider
    }
    zoomMeeting {
      meetingId
      password
    }
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
      ...PositionFragment
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
      name
      startDateTime
      endDateTime
    }
    courseGroups {
      ...CourseGroupFragment
    }
  }
''';

/// Complete query for fetching terms - matches GetTerms exactly
const String getTermsQuery = '''
  $positionFragment
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
  $positionFragment
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