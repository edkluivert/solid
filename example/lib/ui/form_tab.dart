import 'package:flutter/material.dart';
import 'package:formz/formz.dart';
import 'package:solid_x/solid_x.dart';

import '../contact_form_view_model.dart';

class FormTab extends StatelessWidget {
  const FormTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidProvider<ContactFormViewModel>(
      create: ContactFormViewModel.new,
      child: const _FormView(),
    );
  }
}

class _FormView extends StatelessWidget {
  const _FormView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Form (Cubit Style)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SolidConsumer<ContactFormViewModel, ContactFormState>(
          listener: (context, state) {
            if (state.status.isSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Form submission success!')),
              );
            }
            if (state.status.isFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Error')),
              );
            }
          },
          builder: (context, state) {
            final vm = context.solid<ContactFormViewModel>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'No controllers, exactly like Cubit. State is mapped via Formz.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                TextField(
                  onChanged: vm.nameChanged,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    errorText: state.name.displayError != null
                        ? 'Invalid name'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  onChanged: vm.emailChanged,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    errorText: state.email.displayError != null
                        ? 'Invalid email'
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  onChanged: vm.companyChanged,
                  decoration: InputDecoration(
                    labelText: 'Company',
                    border: const OutlineInputBorder(),
                    errorText: state.company.displayError != null
                        ? 'Invalid company'
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: state.isValid && !state.status.isInProgress
                      ? vm.submit
                      : null,
                  icon: state.status.isInProgress
                      ? const SizedBox.shrink()
                      : const Icon(Icons.send_outlined),
                  label: state.status.isInProgress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
