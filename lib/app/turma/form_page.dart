import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:matricular/matricular.dart';
import 'package:matricular_flutter/routes.dart';
import 'package:provider/provider.dart';
import 'package:routefly/routefly.dart';
import 'package:signals/signals_flutter.dart';

import '../api/AppAPI.dart';

class InsertPage extends StatefulWidget {
  const InsertPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MultiProvider(
            providers: [
              Provider(
                create: (_) => context.read<AppAPI>(),
                dispose: (_, instance) => instance.dispose(),
              )
            ],
            child: const InsertPage()
        ));
  }

  @override
  State<InsertPage> createState() => _InsertPageState();
}

class _InsertPageState extends State<InsertPage> {
  AppAPI? appAPI;

  final nomeProfessor = signal('');
  final titulo = signal('');
  final turno = signal('');
  final ano = signal('');
  final horarioInicio = signal('');
  final horarioFim = signal('');
  final telefoneProfessor = signal('');
  late final isValid = computed(() => nomeProfessor().isNotEmpty);
  final nameError = signal<String?>(null);
  final turmaError = signal<String?>(null);
  final anoError = signal<String?>(null);
  final horarioInicioError = signal<String?>(null);
  final horarioFimError = signal<String?>(null);
  final telefoneError = signal<String?>(null);
  final telefoneFormatter = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: { "#": RegExp(r'[0-9]') },
  type: MaskAutoCompletionType.lazy
  );
  final horarioInicioFormatter = MaskTextInputFormatter(
      mask: '%#:&#',
      filter: {
        "#": RegExp(r'[0-9]'),
        "%": RegExp(r'[0-2]'),
        "&": RegExp(r'[0-5]')
      },
      type: MaskAutoCompletionType.lazy
  );
  final horarioFimFormatter = MaskTextInputFormatter(
      mask: '%#:&#',
      filter: {
        "#": RegExp(r'[0-9]'),
        "%": RegExp(r'[0-2]'),
        "&": RegExp(r'[0-5]')
      },
      type: MaskAutoCompletionType.lazy
  );
  final anoFormatter = MaskTextInputFormatter(
      mask: '####',
      filter: { "#": RegExp(r'[0-9]') },
      type: MaskAutoCompletionType.lazy
  );

  List<TurmaDTOTurnoEnum> _turnos = [TurmaDTOTurnoEnum.MATUTINO, TurmaDTOTurnoEnum.VESPERTINO, TurmaDTOTurnoEnum.INTEGRAL];
  TurmaDTOTurnoEnum _selectedTurno = TurmaDTOTurnoEnum.MATUTINO;

  validateForm(BuildContext context) async {
    var ok = true;
    if (nomeProfessor().length > 4) {
      nameError.value = null;
    } else {
      ok = false;
      nameError.value = 'Erro! Mínimo de 4 caracteres';
    }

    if(telefoneFormatter.getUnmaskedText().length == 11){
      telefoneError.value = null;
    } else {
      ok = false;
      telefoneError.value = 'Erro! Telefone deve ter 11 dígitos';
    }

    if (titulo().length > 4) {
      turmaError.value = null;
    } else {
      ok = false;
      turmaError.value = 'Erro! Mínimo de 4 caracteres';
    }

    if (ano().length == 4) {
      anoError.value = null;
    } else {
      ok = false;
      anoError.value = 'Erro! Ano deve ter 4 dígitos';
    }

    if (horarioInicioFormatter.getUnmaskedText().length == 4) {
      horarioInicioError.value = null;
    } else {
      ok = false;
      horarioInicioError.value = 'Erro! horário deve ter 4 dígitos';
    }

    if (horarioFimFormatter.getUnmaskedText().length == 4) {
      horarioFimError.value = null;
    } else {
      ok = false;
      horarioFimError.value = 'Erro! horário deve ter 4 dígitos';
    }

    if (ok) {

      final turmaApi = appAPI?.api.getTurmaControllerApi();

      try {
        final turmaDto = TurmaDTOBuilder();
        turmaDto.nomeProfessor = nomeProfessor();
        turmaDto.titulo = titulo();
        turmaDto.turno = _selectedTurno;
        turmaDto.ano = int.parse(ano());
        turmaDto.horaInicio = horarioInicioFormatter.getUnmaskedText();
        turmaDto.horaFim = horarioFimFormatter.getUnmaskedText();
        turmaDto.telefoneProfessor = telefoneFormatter.getUnmaskedText();

        final responseList =
        await turmaApi?.turmaControllerIncluir(turmaDTO: turmaDto.build());
        debugPrint("Dados turma");
        debugPrint(responseList?.data.toString());
      } on DioException catch (e) {
        if (e.response?.statusCode == 400) {
          var message = e.response?.data as String;
          showMessage(message);
        } else if (e.response?.statusCode == 428) {
          showMessage(e.response?.data as String);
        } else {
          print(
              "Exception when calling ControllerHelloWorldApi->helloWorld: $e\n");
          showMessage(e.response?.data as String);
        }
        return;
      }

      debugPrint("ok validado");
      Navigator.pushNamed(context, '/turma/list').then((_) => setState(() {}));;
    }
  }

  @override
  deactivate(){
    debugPrint("Deactivate insert");
    super.deactivate();
  }
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: TextStyle(fontSize: 22.0)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    appAPI ??= context.read<AppAPI>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: const Text('Cadastro de turma', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          height: MediaQuery.of(context).size.height - 120,
          //height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
          child: Column(
              children: [const Spacer(
                flex: 1,
              ),
              Flexible(
                flex: 3,
                child: TextField(
                  onChanged: nomeProfessor.set,
                  inputFormatters: const [],
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text("Nome do(a) professor(a)"),
                      errorText: nameError.watch(context)),
                ),
              ),
              const Spacer(
                flex: 1,
              ),
                Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: titulo.set,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("Nome da turma"),
                        errorText: turmaError.watch(context)),
                  ),
                ),
              const Spacer(
                flex: 1,
              ),
                Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: ano.set,
                    inputFormatters: [anoFormatter],
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("Ano"),
                        errorText: anoError.watch(context)),
                  ),
                ),
                const Spacer(
                  flex: 1,
                ),
                Flexible(
                  flex: 3,
                  child: DropdownButtonFormField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        label: Text("Turno")),
                    value: _selectedTurno,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTurno = newValue!;
                      });
                    },
                    items: _turnos.map((turno) {
                      return DropdownMenuItem(
                        child: new Text(turno.name),
                        value: turno,
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(
                  flex: 1,
                ),
                Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: horarioInicio.set,
                    inputFormatters: [horarioInicioFormatter],
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "00:00",
                        label: Text("Horário de início"),
                        errorText: horarioInicioError.watch(context)),
                  ),
                ),
                const Spacer(
                  flex: 1,
                ),
                Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: horarioFim.set,
                    inputFormatters: [horarioFimFormatter],
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "00:00",
                        label: Text("Horário de fim"),
                        errorText: horarioFimError.watch(context)),
                  ),
                ),
                const Spacer(
                  flex: 1,
                ),
                Flexible(
                  flex: 3,
                  child: TextField(
                    onChanged: telefoneProfessor.set,
                    inputFormatters: [telefoneFormatter],
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "(99) 99999-9999",
                        label: Text("Telefone do(a) professor(a)"),
                        errorText: telefoneError.watch(context)),
                  ),
                ),
                const Spacer(
                  flex: 1,
                ),
              Flexible(
                flex: 3,
                child: FractionallySizedBox(
                  widthFactor: 0.4,
                  heightFactor: 0.4,
                  child: FilledButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.inversePrimary)),
                    onPressed: isValid.watch(context)
                        ? () {
                      validateForm(context);
                    }
                        : null,
                    child: const Text('Salvar'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}
