import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/course_model.dart';
import 'course_loader.dart';

const _ink = Color(0xFF14233E),
    _blue = Color(0xFF4256E9),
    _paper = Color(0xFFF3F5FC);
typedef CourseLoader = Future<List<CourseData>> Function();
typedef CourseOpener = Future<bool> Function(Uri uri);

class TrainsCatalogue extends StatefulWidget {
  const TrainsCatalogue({super.key, this.loader, this.opener});
  final CourseLoader? loader;
  final CourseOpener? opener;
  @override
  State<TrainsCatalogue> createState() => _TrainsCatalogueState();
}

class _TrainsCatalogueState extends State<TrainsCatalogue>
    with WidgetsBindingObserver {
  List<CourseData> _courses = [];
  bool _loading = true, _failed = false;
  String _query = '', _provider = 'All providers', _tuition = 'All tuition';
  int _request = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _request++;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
      _courses = [];
    });
    try {
      final rows = await (widget.loader ?? loadTrainsCourses)();
      if (!mounted || request != _request) return;
      setState(() {
        _courses = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _courses
        .where(
          (c) =>
              (_provider == 'All providers' || c.providerLabel == _provider) &&
              (_tuition == 'All tuition' || c.tuitionFilter == _tuition) &&
              '${c.title} ${c.summary} ${c.details} ${c.duration} ${c.providerLabel}'
                  .toLowerCase()
                  .contains(_query.trim().toLowerCase()),
        )
        .toList();
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: const Text('Trains'),
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh courses',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Build your next skill',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore CNU and SpeakOut courses. Apply directly with the provider.',
              style: TextStyle(fontSize: 16, height: 1.4, color: _ink),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('trains-search'),
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                labelText: 'Search courses',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _filter('Provider', _provider, const [
                  'All providers',
                  'CNU',
                  'SpeakOut',
                ], (v) => setState(() => _provider = v)),
                _filter('Tuition', _tuition, const [
                  'All tuition',
                  'Paid',
                  'Free',
                  'Contact for tuition',
                ], (v) => setState(() => _tuition = v)),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_failed)
              Column(
                children: [
                  const Text(
                    'Courses could not be loaded. Check your connection and sign in again if your session has expired.',
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              )
            else if (rows.isEmpty)
              Text(
                _courses.isEmpty
                    ? 'No published courses yet. Please check back soon.'
                    : 'No courses match these filters.',
                style: const TextStyle(fontSize: 16),
              )
            else
              ...rows.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => TrainsCourseDetail(
                              course: c,
                              opener: widget.opener,
                            ),
                          ),
                        );
                        if (mounted) await _load();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CourseCover(url: c.fullImage),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.providerLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CourseData.plain(c.title),
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CourseData.plain(c.summary),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  CourseData.plain(c.duration),
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  c.tuitionLabel,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: _blue,
                                  ),
                                ),
                                if (c.isSpeakOut)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Registration and approval required',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                const Text(
                                  'View course details →',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filter(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> changed,
  ) => SizedBox(
    width: 250,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) changed(v);
      },
    ),
  );
}

class CourseCover extends StatelessWidget {
  const CourseCover({super.key, this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFFE5EAFE),
      child: Center(child: Icon(Icons.school_outlined, size: 52, color: _blue)),
    );
    final uri = Uri.tryParse(url ?? '');
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: uri?.scheme == 'https'
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

class TrainsCourseDetail extends StatelessWidget {
  const TrainsCourseDetail({super.key, required this.course, this.opener});
  final CourseData course;
  final CourseOpener? opener;
  Future<void> _open(BuildContext context) async {
    final uri = course.applicationUri;
    if (uri == null) return;
    bool opened;
    try {
      opened =
          await (opener?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the application website. Please try again.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      title: const Text('Course details'),
      backgroundColor: _paper,
      foregroundColor: _ink,
      elevation: 0,
    ),
    body: ListView(
      children: [
        CourseCover(url: course.fullImage),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                course.providerLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                CourseData.plain(course.title),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                CourseData.plain(course.duration),
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 12),
              Text(
                course.tuitionLabel,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: _blue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                CourseData.plain(course.details),
                style: const TextStyle(fontSize: 17, height: 1.6),
              ),
              const SizedBox(height: 24),
              Text(
                course.applicationNotice,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('trains-apply'),
                onPressed: course.applicationUri == null
                    ? null
                    : () => _open(context),
                icon: const Icon(Icons.open_in_new),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    course.isSpeakOut
                        ? 'Register on SpeakOut'
                        : 'Apply on provider website',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ),
              if (course.applicationUri == null)
                const Text(
                  'Application link unavailable. Please contact the provider.',
                  style: TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
