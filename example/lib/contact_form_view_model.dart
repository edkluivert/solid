import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:solid_x/solid_x.dart';

// ---------------------------------------------------------------------------
// Formz Inputs
// ---------------------------------------------------------------------------

enum NameValidationError { empty, tooShort }

class NameInput extends FormzInput<String, NameValidationError> {
  const NameInput.pure() : super.pure('');
  const NameInput.dirty([super.value = '']) : super.dirty();

  @override
  NameValidationError? validator(String value) {
    if (value.isEmpty) return NameValidationError.empty;
    if (value.length < 2) return NameValidationError.tooShort;
    return null;
  }
}

enum EmailValidationError { invalid }

class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();
  static final _emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  EmailValidationError? validator(String value) {
    return _emailRx.hasMatch(value) ? null : EmailValidationError.invalid;
  }
}

enum CompanyValidationError { empty }

class CompanyInput extends FormzInput<String, CompanyValidationError> {
  const CompanyInput.pure() : super.pure('');
  const CompanyInput.dirty([super.value = '']) : super.dirty();

  @override
  CompanyValidationError? validator(String value) {
    return value.isNotEmpty ? null : CompanyValidationError.empty;
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ContactFormState extends Equatable {
  final NameInput name;
  final EmailInput email;
  final CompanyInput company;
  final FormzSubmissionStatus status;
  final String? errorMessage;

  const ContactFormState({
    this.name = const NameInput.pure(),
    this.email = const EmailInput.pure(),
    this.company = const CompanyInput.pure(),
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  });

  // Use formz multi-input validator
  bool get isValid => Formz.validate([name, email, company]);

  ContactFormState copyWith({
    NameInput? name,
    EmailInput? email,
    CompanyInput? company,
    FormzSubmissionStatus? status,
    String? errorMessage,
  }) {
    return ContactFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      company: company ?? this.company,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [name, email, company, status, errorMessage];
}

// ---------------------------------------------------------------------------
// ViewModel (Identical layout to Cubit)
// ---------------------------------------------------------------------------

class ContactFormViewModel extends Solid<ContactFormState> {
  ContactFormViewModel() : super(const ContactFormState());

  void nameChanged(String value) {
    push(
      state.copyWith(
        name: NameInput.dirty(value),
        status: FormzSubmissionStatus.initial,
      ),
    );
  }

  void emailChanged(String value) {
    push(
      state.copyWith(
        email: EmailInput.dirty(value),
        status: FormzSubmissionStatus.initial,
      ),
    );
  }

  void companyChanged(String value) {
    push(
      state.copyWith(
        company: CompanyInput.dirty(value),
        status: FormzSubmissionStatus.initial,
      ),
    );
  }

  Future<void> submit() async {
    if (!state.isValid) return;

    push(state.copyWith(status: FormzSubmissionStatus.inProgress));

    try {
      await Future.delayed(const Duration(seconds: 2)); // API call
      push(state.copyWith(status: FormzSubmissionStatus.success));
    } catch (_) {
      push(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          errorMessage: 'Form submission failed',
        ),
      );
    }
  }
}
