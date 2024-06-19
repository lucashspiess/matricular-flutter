import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:matricular/matricular.dart';
import 'package:provider/provider.dart';
import 'package:routefly/routefly.dart';
import 'package:signals/signals_flutter.dart';

import '../api/AppAPI.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

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
            child: const EditPage()
        ));
  }

  @override
  State<EditPage> createState() => _EditPageState();
}



class _EditPageState extends State<EditPage> {

  @override
  initState() {
    super.initState();
  }
  AppAPI? appAPI;

  final nomeProfessor = signal('');
  final idValue = signal<int?>(null);
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

  final nomeProfessorTextController = TextEditingController();
  final tituloTextController = TextEditingController();
  final turnoTextController = TextEditingController();
  final anoTextController = TextEditingController();
  final horarioInicioTextController = TextEditingController();
  final horarioFimTextController = TextEditingController();
  final telefoneProfessorTextController = TextEditingController();
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

  final List<String> _turnos = [TurmaDTOTurnoEnum.MATUTINO.name, TurmaDTOTurnoEnum.VESPERTINO.name, TurmaDTOTurnoEnum.INTEGRAL.name];
  String _selectedTurno = TurmaDTOTurnoEnum.MATUTINO.name;

  validateForm(BuildContext context) async {
    var ok = true;
    if(horarioInicioFormatter.getUnmaskedText().isNotEmpty){
      horarioInicio.set(horarioInicioFormatter.getUnmaskedText());
    }
    if(horarioFimFormatter.getUnmaskedText().isNotEmpty){
      horarioFim.set(horarioFimFormatter.getUnmaskedText());
    }
    if(telefoneFormatter.getUnmaskedText().isNotEmpty){
      telefoneProfessor.set(telefoneFormatter.getUnmaskedText());
    }


    if (nomeProfessor().length > 4) {
      nameError.value = null;
    } else {
      ok = false;
      nameError.value = 'Erro! Mínimo de 4 caracteres';
    }

    if(telefoneProfessor().length == 11){
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

    if (horarioInicio().length == 4) {
      horarioInicioError.value = null;
    } else {
      ok = false;
      horarioInicioError.value = 'Erro! horário deve ter 4 dígitos';
    }

    if (horarioFim().length == 4) {
      horarioFimError.value = null;
    } else {
      ok = false;
      horarioFimError.value = 'Erro! horário deve ter 4 dígitos';
    }

    if (ok) {

      final turmaApi = appAPI?.api.getTurmaControllerApi();

      try {
        if(horarioInicio.value=='' || horarioInicio.value.length>4){
          horarioInicio.set(horarioInicioFormatter.getUnmaskedText());
          horarioFim.set(horarioFimFormatter.getUnmaskedText());
          telefoneProfessor.set(telefoneFormatter.getUnmaskedText());
        }
        final turmaDto = TurmaDTOBuilder();
        turmaDto.nomeProfessor = nomeProfessor();
        turmaDto.titulo = titulo();
        turmaDto.turno = TurmaDTOTurnoEnum.valueOf(_selectedTurno);
        turmaDto.ano = int.parse(ano());
        turmaDto.horaInicio = horarioInicio();
        turmaDto.horaFim = horarioFim();
        turmaDto.telefoneProfessor = telefoneProfessor();

        final responseList =
        await turmaApi?.turmaControllerAlterar(id: Routefly.query['id'] ?? idValue(),turmaDTO: turmaDto.build());
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
      Navigator.pushNamed(context, '/turma/list').then((_) => setState(() {}));
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
    initData(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: Text('Editar ${titulo()}', style: const TextStyle(color: Colors.white)),
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
                  controller: nomeProfessorTextController,
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
                  controller: tituloTextController,
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
                  controller: anoTextController,
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
                      child: new Text(turno),
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
                  controller: horarioInicioTextController,
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
                  controller: horarioFimTextController,
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
                  controller: telefoneProfessorTextController,
                  inputFormatters: [telefoneFormatter],
                  decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "(99) 99999-9999",
                      label: Text("Telefone do(a) professor(a)"),
                      errorText: telefoneError.watch(context)),
                ),
              ),
              Spacer(
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

  void initData(BuildContext context) {
    if(appAPI == null){
      appAPI = context.read<AppAPI>();
      idValue.set(Routefly.query['id'] ?? idValue());
      appAPI?.api.getTurmaControllerApi().turmaControllerObterPorId(id: idValue()??0)
          .then((turmaResponse) {
        var turmaDto = turmaResponse.data;
        nomeProfessor.set(turmaDto!.nomeProfessor??'');
        titulo.set(turmaDto.titulo??'');
        ano.set(turmaDto.ano.toString()??'');
        turno.set(turmaDto.turno?.name??'');
        horarioInicio.set(turmaDto.horaInicio??'');
        horarioFim.set(turmaDto.horaFim??'');
        telefoneProfessor.set(turmaDto.telefoneProfessor??'');
        nomeProfessorTextController.text = nomeProfessor.watch(context);
        tituloTextController.text = titulo.watch(context);
        anoTextController.text = ano.watch(context);
        _selectedTurno = turno.watch(context);
        horarioInicioTextController.text = horarioInicioFormatter.maskText(horarioInicio.watch(context));
        horarioFimTextController.text = horarioFimFormatter.maskText(horarioFim.watch(context));
        telefoneProfessorTextController.text = telefoneFormatter.maskText(telefoneProfessor.watch(context));
      });

    }
  }

  Route<dynamic> routeBuilder(BuildContext context, RouteSettings settings) {
    return PageRouteBuilder(
      pageBuilder: (_, a1, a2) => const EditPage(),
      transitionsBuilder: (_, a1, a2, child) {
        return FadeTransition(opacity: a1, child: child);
      },
    );
  }

}