import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_template/core/res/button_style.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/custom_hooks/use_effect_once.dart';
import '../../../core/custom_hooks/use_form_field_state_key.dart';
import '../../../core/extensions/context_extension.dart';
import '../../../core/extensions/exception_extension.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/show_indicator.dart';
import '../use_cases/change_email_password.dart';
import 'reset_email_password_page.dart';
import 'top_email_feature_page.dart';
import 'widgets/passward_text_field.dart';

class ChangeEmailPasswordPage extends HookConsumerWidget {
  const ChangeEmailPasswordPage({super.key});

  static String get pageName => 'change_email_password';
  static String get pagePath => '${TopEmailFeaturePage.pagePath}/$pageName';

  /// go_routerの画面遷移
  static void push(BuildContext context) {
    context.push(pagePath);
  }

  /// 従来の画面遷移
  static Future<void> showNav1(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      CupertinoPageRoute(
        settings: RouteSettings(name: pageName),
        builder: (_) => const ChangeEmailPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollController = useScrollController();
    final oldPasswordFormFieldKey = useFormFieldStateKey();
    final newPasswordFormFieldKey = useFormFieldStateKey();

    final focusNode = useFocusNode();

    useEffectOnce(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        /// フォーカスを当ててキーボード表示
        focusNode.requestFocus();
      });
      return null;
    });

    return GestureDetector(
      onTap: context.hideKeyboard,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'パスワード変更',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Scrollbar(
          controller: scrollController,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                /// 現在のパスワード
                PasswordTextField(
                  textFormFieldKey: oldPasswordFormFieldKey,
                  focusNode: focusNode,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 32,
                  ),
                  hintText: '大文字小文字含む英数字8桁以上',
                  title: '現在のパスワードを入力',
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => focusNode.nextFocus(),
                ),

                /// 変更後パスワード
                PasswordTextField(
                  textFormFieldKey: newPasswordFormFieldKey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                  ).copyWith(bottom: 16),
                  hintText: '大文字小文字含む英数字8桁以上',
                  title: '変更後のパスワードを入力',
                ),

                /// パスワードを忘れた
                TextButton(
                  onPressed: () {
                    ResetEmailPasswordPage.push(context);
                  },
                  child: Text(
                    'パスワードを忘れた',
                    style: context.bodyStyle.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        persistentFooterAlignment: AlignmentDirectional.center,
        persistentFooterButtons: [
          FilledButton(
            style: ButtonStyles.normal(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '変更する',
                style: context.bodyStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () async {
              final isValidOldPassword =
                  oldPasswordFormFieldKey.currentState?.validate() ?? false;
              final isValidNewPassword =
                  newPasswordFormFieldKey.currentState?.validate() ?? false;

              if (!isValidOldPassword || !isValidNewPassword) {
                logger.info('invalid input data');
                return;
              }
              final oldPassword = oldPasswordFormFieldKey.currentState?.value;
              final newPassword = newPasswordFormFieldKey.currentState?.value;
              if (oldPassword == null || newPassword == null) {
                return;
              }

              try {
                showIndicator(context);
                await ref.read(changeEmailPasswordProvider)(
                  oldPassword: oldPassword,
                  newPassword: newPassword,
                );
                if (context.mounted) {
                  dismissIndicator(context);
                  await showOkAlertDialog(context: context, title: '変更しました');
                }
                if (context.mounted) {
                  context.pop();
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  dismissIndicator(context);
                  showOkAlertDialog(
                    context: context,
                    title: 'エラー',
                    message: e.errorMessage,
                  ).ignore();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
