import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/core/di/service_locator.dart';
import 'package:mediconnect/features/consultation/presentation/bloc/prescription_bloc.dart';
import 'package:signature/signature.dart';

class PrescriptionPage extends StatelessWidget {
  final String roomId;

  const PrescriptionPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PrescriptionBloc>(),
      child: _PrescriptionView(roomId: roomId),
    );
  }
}

class _PrescriptionView extends StatefulWidget {
  final String roomId;

  const _PrescriptionView({required this.roomId});

  @override
  State<_PrescriptionView> createState() => _PrescriptionViewState();
}

class _PrescriptionViewState extends State<_PrescriptionView> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();
  final List<TextEditingController> _medicationControllers = [
    TextEditingController(),
  ];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _instructionsController.dispose();
    for (final c in _medicationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medicationControllers.add(TextEditingController());
    });
  }

  void _removeMedication(int index) {
    if (_medicationControllers.length > 1) {
      setState(() {
        _medicationControllers[index].dispose();
        _medicationControllers.removeAt(index);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final medications = _medicationControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      context.read<PrescriptionBloc>().add(
        PrescriptionFormSubmitted(
          roomId: widget.roomId,
          // TODO: Replace with actual auth data
          doctorId: 'doctor_001',
          doctorName: 'Dr. García',
          patientId: 'patient_001',
          patientName: 'Juan Pérez',
          diagnosis: _diagnosisController.text.trim(),
          medications: medications,
          instructions: _instructionsController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Receta Médica'),
        backgroundColor: const Color(0xFF137FEC),
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state is PrescriptionSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isOffline
                      ? '✅ Receta guardada localmente (se sincronizará cuando haya conexión)'
                      : '✅ Receta guardada exitosamente',
                ),
                backgroundColor: state.isOffline ? Colors.orange : Colors.green,
              ),
            );
            context.pop();
          }
          if (state is PrescriptionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PrescriptionSaving) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PrescriptionAwaitingSignature) {
            return _SignatureView(prescription: state.prescription);
          }

          // Form
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF137FEC), Color(0xFF0D5BB5)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receta Médica Digital',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'MediConnect',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Diagnosis
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(
                      labelText: 'Diagnóstico',
                      prefixIcon: const Icon(Icons.health_and_safety),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'El diagnóstico es requerido'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Medications
                  Row(
                    children: [
                      const Text(
                        'Medicamentos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addMedication,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._medicationControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Medicamento ${index + 1}',
                                hintText: 'Ej: Paracetamol 500mg - 1 cada 8h',
                                prefixIcon: const Icon(Icons.medication),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) {
                                if (index == 0 &&
                                    (v == null || v.trim().isEmpty)) {
                                  return 'Al menos un medicamento es requerido';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (_medicationControllers.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeMedication(index),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Instructions
                  TextFormField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      labelText: 'Indicaciones / Instrucciones',
                      prefixIcon: const Icon(Icons.note_alt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Las indicaciones son requeridas'
                        : null,
                  ),
                  const SizedBox(height: 32),

                  // Submit
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.draw),
                    label: const Text(
                      'Continuar a Firma',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF137FEC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignatureView extends StatefulWidget {
  final dynamic prescription;

  const _SignatureView({required this.prescription});

  @override
  State<_SignatureView> createState() => _SignatureViewState();
}

class _SignatureViewState extends State<_SignatureView> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
    exportPenColor: Colors.black,
  );

  bool _isSigned = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, firme primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final data = await _signatureController.toPngBytes();
    if (data != null) {
      final base64Signature = base64Encode(data);
      if (!mounted) return;

      context.read<PrescriptionBloc>().add(PrescriptionSigned(base64Signature));
      setState(() => _isSigned = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prescription summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Receta',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Diagnóstico',
                  value: widget.prescription.diagnosis,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Medicamentos:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ...widget.prescription.medications.map<Widget>(
                  (m) => Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Color(0xFF137FEC),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(m)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Indicaciones',
                  value: widget.prescription.instructions,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Signature pad
          const Text(
            'Firma del Doctor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dibuje su firma en el recuadro inferior',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _isSigned ? Colors.green : const Color(0xFF137FEC),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Signature(
                controller: _signatureController,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Signature actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _signatureController.clear();
                    setState(() => _isSigned = false);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpiar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: Icon(_isSigned ? Icons.check : Icons.draw),
                  label: Text(_isSigned ? 'Firmado ✓' : 'Capturar Firma'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _isSigned
                        ? Colors.green
                        : const Color(0xFF137FEC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save buttons
          if (_isSigned) ...[
            ElevatedButton.icon(
              onPressed: () {
                context.read<PrescriptionBloc>().add(
                  const PrescriptionSaveRequested(),
                );
              },
              icon: const Icon(Icons.cloud_upload),
              label: const Text(
                'Guardar Receta',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                context.read<PrescriptionBloc>().add(
                  const PrescriptionSaveRequested(isOffline: true),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Guardar Offline (sin conexión)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
