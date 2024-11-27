import 'package:flutter/material.dart';
import 'package:gamers_gram/data/services/tournaments_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CreateTournamentView extends StatefulWidget {
  const CreateTournamentView({super.key});

  @override
  _CreateTournamentViewState createState() => _CreateTournamentViewState();
}

class _CreateTournamentViewState extends State<CreateTournamentView> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _gameController = TextEditingController();
  final _platformController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _prizePoolController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _rulesController = TextEditingController();

  // Date and Time Controllers
  DateTime? _startDate;
  DateTime? _registrationEndDate;
  DateTime? _endDate;

  // Dropdown values
  String _selectedFormat = 'Single Elimination';
  String _selectedParticipationType = 'Open';

  final List<String> _formatOptions = [
    'Single Elimination',
    'Double Elimination',
    'Round Robin',
    'Group Stage'
  ];

  final List<String> _participationTypeOptions = [
    'Open',
    'Invite Only',
    'Qualification Required'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Tournament Name',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _gameController,
                label: 'Game',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a game' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _platformController,
                label: 'Platform',
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a platform' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _entryFeeController,
                      label: 'Entry Fee',
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter entry fee'
                          : double.tryParse(value) == null
                              ? 'Invalid number'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _prizePoolController,
                      label: 'Prize Pool',
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter prize pool'
                          : double.tryParse(value) == null
                              ? 'Invalid number'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _maxParticipantsController,
                label: 'Max Participants',
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty
                    ? 'Please enter max participants'
                    : int.tryParse(value) == null
                        ? 'Invalid number'
                        : null,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Registration End Date',
                date: _registrationEndDate,
                onDateChanged: (date) =>
                    setState(() => _registrationEndDate = date),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'Start Date',
                date: _startDate,
                onDateChanged: (date) => setState(() => _startDate = date),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(
                label: 'End Date',
                date: _endDate,
                onDateChanged: (date) => setState(() => _endDate = date),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  labelText: 'Tournament Format',
                  border: OutlineInputBorder(),
                ),
                items: _formatOptions
                    .map((format) => DropdownMenuItem(
                          value: format,
                          child: Text(format),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedFormat = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedParticipationType,
                decoration: const InputDecoration(
                  labelText: 'Participation Type',
                  border: OutlineInputBorder(),
                ),
                items: _participationTypeOptions
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedParticipationType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rulesController,
                decoration: const InputDecoration(
                  labelText: 'Tournament Rules (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createTournament,
                child: const Text('Create Tournament'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateChanged,
  }) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2025),
        );
        onDateChanged(pickedDate);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select Date',
        ),
      ),
    );
  }

  void _createTournament() async {
    if (_formKey.currentState!.validate()) {
      // Check date validations
      if (_registrationEndDate == null ||
          _startDate == null ||
          _endDate == null) {
        Get.snackbar('Error', 'Please select all dates',
            backgroundColor: Colors.red);
        return;
      }

      // Validate dates
      if (_registrationEndDate!.isAfter(_startDate!) ||
          _startDate!.isAfter(_endDate!)) {
        Get.snackbar(
          'Error',
          'Invalid dates. Registration end must be before start, and start before end.',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Prepare tournament data
      final tournament = Tournament(
        id: '', // Firebase will generate this
        name: _nameController.text,
        game: _gameController.text,
        platform: _platformController.text,
        entryFee: double.parse(_entryFeeController.text),
        prizePool: double.parse(_prizePoolController.text),
        format: _selectedFormat,
        participationType: _selectedParticipationType,
        maxParticipants: int.parse(_maxParticipantsController.text),
        status: 'Open', // Default status
        startDate: _startDate!,
        registrationEndDate: _registrationEndDate!,
        endDate: _endDate!,
        rules: _rulesController.text.isNotEmpty ? [_rulesController.text] : [],
        prizes: {
          'first': double.parse(_prizePoolController.text) * 0.6,
          'second': double.parse(_prizePoolController.text) * 0.3,
          'third': double.parse(_prizePoolController.text) * 0.1,
        },
        createdBy: '', // This will be set by the controller
      );

      final tournamentId =
          await TournamentService().createTournament(tournament);

      if (tournamentId != null) {
        Get.snackbar(
          'Success',
          'Tournament created successfully!',
          backgroundColor: Colors.green,
        );
        Get.back(); // Return to previous screen
      } else {
        Get.snackbar(
          'Error',
          'Failed to create tournament',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameController.dispose();
    _platformController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    _maxParticipantsController.dispose();
    _rulesController.dispose();
    super.dispose();
  }
}
