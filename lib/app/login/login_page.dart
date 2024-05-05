import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matricular/matricular.dart';
import 'package:matricular_flutter/app/utils/config_state.dart';
import 'package:matricular_flutter/routes.dart';
import 'package:provider/provider.dart';
import 'package:routefly/routefly.dart';
import 'package:signals/signals_flutter.dart';

import '../api/AppAPI.dart';
import 'login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MultiProvider(
          providers: [
            Provider(
              create: (_) => context.read<ConfigState>(),
              dispose: (_, instance) => instance.dispose(),
            ),
            Provider(create: (_) => context.read<AppAPI>())
          ],
          child: const LoginPage(),
        )
    );
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginState state = LoginState();
  late AppAPI appAPI;
  late Matricular matriculaApi;

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 22.0)),
    ));
  }

  validateForm(BuildContext context) async {
    var ok = false;
    if (state.password().length > 4) {
      state.passwordError.value = null;
      ok = true;
    } else {
      state.passwordError.value = 'Erro! Mínimo de 6 caracteres';
    }

    if (ok) {
      final authApi = matriculaApi.getAuthAPIApi();
      //if(authApi ==  null) return;

      try {
        var authBuilder = AuthDTOBuilder();
        authBuilder.login = state.login();
        authBuilder.senha = state.password();
        debugPrint(authBuilder.build().toString());

        final responseList = await authApi.login(authDTO: authBuilder.build());
        debugPrint("Dados do Login");
        debugPrint(responseList.data.toString());
        if (responseList.statusCode == 200) {
          appAPI.config.token.set(responseList.data!.accessToken ?? "");

          Routefly.navigate(routePaths.matricula.home);
        } else {
          message() {
            showMessage(context, "Login Falhou: ${responseList.data}");
          }
          message();
        }
      } on DioException catch (e) {
        MessageResponseBuilder responseBuilder = MessageResponseBuilder();
        responseBuilder.message = e.response?.data["message"];
        responseBuilder.status = e.response?.data["status"];
        responseBuilder.error = e.response?.data["error"];
        responseBuilder.code = e.response?.data["code"];
        MessageResponse response = responseBuilder.build();


        message() {

          showMessage(context, "Login Falhou: ${response.message}");
        }
        message();
        print(
            "Exception when calling: $e\n${e.response}");
      }
      ;
    }
  }

  @override
  Widget build(BuildContext context) {
    appAPI = context.read<AppAPI>();
    matriculaApi = appAPI.api;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Tela de login'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          height: MediaQuery.of(context).size.height - 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Flexible(
                flex: 6,
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Image(
                        image: AssetImage("./images/logo.png"),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(
                flex: 2,
              ),
              Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: this.state.login.set,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), label: Text("cpf")),
                  )),
              const Spacer(
                flex: 1,
              ),
              Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: this.state.password.set,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        label: const Text("senha"),
                        errorText: this.state.passwordError.watch(context)),
                    enableSuggestions: false,
                    autocorrect: false,
                    obscureText: true,
                  )),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Flexible(
                  flex: 2,
                  child: Text(
                    'Esqueceu a senha',
                  ),
                ),
              ),
              Flexible(
                flex: 3,
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  heightFactor: 0.4,
                  child: FilledButton(
                    onPressed: this.state.isValid.watch(context)
                        ? () => {validateForm(context)}
                        : null,
                    child: const Text('Login'),
                  ),
                ),
              ),
              const Spacer(
                flex: 2,
              ),
              Flexible(
                flex: 2,
                child: TextButton(
                  onPressed: () {
                    Routefly.push(routePaths.prefs);
                  },
                  child: const Text(
                    'Alterar URL Servidor:',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
