import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_cubit.dart';
import '../../../../core/localization/language_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Language / اللغة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, state) {
              return Column(
                children: [
                  RadioListTile<AppLanguage>(
                    title: const Text('English'),
                    value: AppLanguage.en,
                    groupValue: state.language,
                    onChanged: (AppLanguage? language) {
                      if (language != null) {
                        context.read<LanguageCubit>().setLanguage(language);
                      }
                    },
                  ),
                  RadioListTile<AppLanguage>(
                    title: const Text('العربية'),
                    value: AppLanguage.ar,
                    groupValue: state.language,
                    onChanged: (AppLanguage? language) {
                      if (language != null) {
                        context.read<LanguageCubit>().setLanguage(language);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
