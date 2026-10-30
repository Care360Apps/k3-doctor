import 'package:doctro/constant/color_constant.dart';
import 'package:doctro/constant/common_function.dart';
import 'package:doctro/localization/localization_constant.dart';
import 'package:doctro/model/doctor_note.dart';
import 'package:doctro/retrofit/api_header.dart';
import 'package:doctro/retrofit/base_model.dart';
import 'package:doctro/retrofit/network_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constant/app_string.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  bool _loading = false;
  List<DoctorNote> _notes = [];
  int? _editingNoteId;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<BaseModel<DoctorNotesResponse>> _fetchNotes() async {
    DoctorNotesResponse response;
    setState(() {
      _loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).doctorNotes();
      setState(() {
        _loading = false;
        _notes = response.data ?? [];
      });
    } catch (error) {
      setState(() {
        _loading = false;
      });
      CommonFunction.toastMessage(
        getTranslated(context, AppString.no_notes_yet) ?? 'Failed to load notes.',
      );
      return BaseModel();
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<DoctorNotesResponse>> _createNote() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      return BaseModel();
    }

    DoctorNotesResponse response;
    setState(() {
      _loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).createDoctorNote({
        'title': title,
        'body': body,
      });
      setState(() {
        _loading = false;
        _titleController.clear();
        _bodyController.clear();
      });
      await _fetchNotes();
    } catch (error) {
      setState(() {
        _loading = false;
      });
      CommonFunction.toastMessage(
        getTranslated(context, AppString.save_note) ?? 'Failed to save note.',
      );
      return BaseModel();
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<DoctorNotesResponse>> _updateNote() async {
    final String title = _titleController.text.trim();
    final String body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty || _editingNoteId == null) {
      return BaseModel();
    }

    DoctorNotesResponse response;
    setState(() {
      _loading = true;
    });
    try {
      // Reuse the create endpoint with an ID hint; backend will update when ID is present.
      response = await RestClient(RetroApi().dioData()).createDoctorNote({
        'id': _editingNoteId,
        'title': title,
        'body': body,
      });
      setState(() {
        _loading = false;
        _editingNoteId = null;
        _titleController.clear();
        _bodyController.clear();
      });
      await _fetchNotes();
    } catch (error) {
      setState(() {
        _loading = false;
      });
      CommonFunction.toastMessage(
        getTranslated(context, AppString.save_note) ?? 'Failed to update note.',
      );
      return BaseModel();
    }
    return BaseModel()..data = response;
  }

  Future<void> _deleteNote(int id) async {
    setState(() {
      _loading = true;
    });
    try {
      await RestClient(RetroApi().dioData()).deleteDoctorNote(id);
      setState(() {
        _loading = false;
        if (_editingNoteId == id) {
          _editingNoteId = null;
          _titleController.clear();
          _bodyController.clear();
        }
      });
      await _fetchNotes();
    } catch (error) {
      setState(() {
        _loading = false;
      });
      CommonFunction.toastMessage(
        getTranslated(context, AppString.no_notes_yet) ?? 'Failed to delete note.',
      );
    }
  }

  Future<void> _onSavePressed() async {
    if (_loading) return;
    if (_editingNoteId == null) {
      await _createNote();
    } else {
      await _updateNote();
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy, HH:mm').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = getTranslated(context, AppString.drawer_notes) ?? 'Notes';
    final subtitleText = getTranslated(context, AppString.note_body) ?? 'Write private notes for your consultations.';
    final isEditing = _editingNoteId != null;

    OutlineInputBorder _inputBorder(Color borderColor) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          titleText,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: loginButton,
        foregroundColor: colorWhite,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorWhite,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.note_title) ?? 'New note',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 13,
                        color: hintColor.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: getTranslated(context, AppString.note_title) ?? 'Title',
                        filled: true,
                        fillColor: const Color(0xFFF3F6FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: _inputBorder(Colors.transparent),
                        enabledBorder: _inputBorder(Colors.transparent),
                        focusedBorder: _inputBorder(loginButton.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: getTranslated(context, AppString.note_body) ?? 'Write your note...',
                        filled: true,
                        fillColor: const Color(0xFFF3F6FB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: _inputBorder(Colors.transparent),
                        enabledBorder: _inputBorder(Colors.transparent),
                        focusedBorder: _inputBorder(loginButton.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onSavePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: loginButton,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                isEditing
                                    ? (getTranslated(context, AppString.save_note) ?? 'Update Note')
                                    : (getTranslated(context, AppString.save_note) ?? 'Save Note'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _notes.isEmpty
                  ? Center(
                      child: Text(
                        getTranslated(context, AppString.no_notes_yet) ?? 'No notes yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: hintColor),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            if (note.id == null) return false;
                            await _deleteNote(note.id!);
                            return false;
                          },
                          child: GestureDetector(
                            onTap: () {
                              if (note.id != null) {
                                setState(() {
                                  _editingNoteId = note.id;
                                  _titleController.text = note.title ?? '';
                                  _bodyController.text = note.body ?? '';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorWhite,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: black.withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: hintColor,
                                          ),
                                        ),
                                      ),
                                      if (note.createdAt != null)
                                        Text(
                                          _formatDate(note.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    note.body ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _notes.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

