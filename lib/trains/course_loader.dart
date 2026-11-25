import '../retrofit/api_header.dart';
import '../retrofit/apis.dart';
import '../model/course_model.dart';

Future<List<CourseData>> loadTrainsCourses() async {
  final response = await RetroApi().dioData().get('${Apis.baseUrl}courses');
  final data = CoursesResponse.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
  if (data.success != true) throw StateError('Catalogue unavailable');
  return data.data ?? [];
}
