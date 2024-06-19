import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'dart:html';
import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricular/matricular.dart';
import 'package:matricular_flutter/app/api/AppAPI.dart';
import 'package:matricular_flutter/app/utils/config_state.dart';
import 'package:matricular_flutter/routes.dart';
import 'package:provider/provider.dart';
import 'package:routefly/routefly.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

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
              child: const StartPage(),
            ));
  }

  Future<Response<BuiltList<TurmaDTO>>> _getData(
      TurmaControllerApi turmaApi) async {
    try {
      var dado = await turmaApi.turmaControllerListAll();
      return dado;
    } on DioException catch (e) {
      debugPrint("Erro home:${e.response}");
      return Future.value([] as FutureOr<Response<BuiltList<TurmaDTO>>>?);
    }
  }

  void _exibirPopupDeMensagem(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download'),
          content: Text('Download do arquivo $fileName realizado com sucesso.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Fechar o popup
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    TurmaControllerApi? turmaApi =
        context.read<AppAPI>().api.getTurmaControllerApi();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[300],
        title: const Text('Turmas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Routefly.pushNavigate(routePaths.turma.form);
            }),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                Routefly.navigate(routePaths.login);
              })
        ],
      ),
      body: FutureBuilder<Response<BuiltList<TurmaDTO>>>(
          future: _getData(turmaApi),
          builder:
              (context, AsyncSnapshot<Response<BuiltList<TurmaDTO>>> snapshot) {
            return buildListView(snapshot, context);
          }),
      bottomNavigationBar: Container(
          color: Colors.blue[300],
          child: Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () {
                    Routefly.navigate(routePaths.matricula.home);
                  }),
              IconButton(
                  icon: const Icon(Icons.chair_alt, color: Colors.white),
                  onPressed: () {
                    Routefly.pushNavigate(routePaths.turma.list);
                  })
            ],
          )),
    );
  }

  Widget buildListView(AsyncSnapshot<Response<BuiltList<TurmaDTO>>> snapshot,
      BuildContext context) {
    TurmaControllerApi? turmaControllerApi =
        context.read<AppAPI>().api.getTurmaControllerApi();
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data?.data?.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
              child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.horizontal,
                  onDismissed: (DismissDirection direction) {
                    if (direction == DismissDirection.endToStart) {
                      turmaControllerApi.turmaControllerRemover(
                          id: snapshot.data!.data?[index].id ?? 0);
                    }
                  },
                  background: const ColoredBox(
                    color: Colors.orange,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.pending_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                  secondaryBackground: const ColoredBox(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  confirmDismiss: (DismissDirection direction) async {
                    if (direction == DismissDirection.endToStart) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(
                                'Tem certeza que deseja excluir a ${snapshot.data!.data?[index].titulo}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Não'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sim'),
                              )
                            ],
                          );
                        },
                      );
                      log('Deletion confirmed: $confirmed');
                      return confirmed;
                    } else {
                      Navigator.pushNamed(context, '${routePaths.turma.path}/${snapshot.data!.data?[index].id}');

                      // Routefly.pushNavigate('${routePaths.turma.path}/${snapshot.data!.data?[index].id}');
                    }
                    return null;
                  },
                  child: SizedBox(
                    height: 161,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      color: Theme.of(context).colorScheme.inversePrimary,
                      elevation: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.chair_alt,
                                size: 100, color: Colors.white),
                            title: Text("${snapshot.data!.data?[index].titulo}",
                                style: const TextStyle(fontSize: 22.0)),
                            subtitle: Text(
                                "Professor: ${snapshot.data!.data?[index].nomeProfessor}\n\n${snapshot.data!.data?[index].turno}             ${snapshot.data!.data?[index].quantidadeAlunos} alunos",
                                style: const TextStyle(fontSize: 18.0)),
                          )
                        ],
                      ),
                    ),
                  )));
        },
      );
    } else if (snapshot.hasError) {
      Routefly.navigate(routePaths.login);
      return const Text('Erro ao acessar dados');
    } else {
      return const CircularProgressIndicator();
    }
  }

  Text buildItemList(
      AsyncSnapshot<Response<BuiltList<MatriculaDTO>>> snapshot, int index) {
    return Text("nome:${snapshot.data!.data?[index]}");
  }

  setState(Null Function() param0) {}
}
