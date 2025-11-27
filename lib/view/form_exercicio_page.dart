import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ficha_de_exercicios/model/exercicio.dart';
import 'package:flutter/material.dart';

class FormExercicioPage extends StatefulWidget {
  final String uid; // ID do usuário logado
  final String rotinaId; // ID da rotina que pertence ao usuário
  final Exercicio? exercicio; // Exercício existente (opcional)

  const FormExercicioPage({
    super.key,
    required this.uid,
    required this.rotinaId,
    this.exercicio,
  });

  @override
  State<FormExercicioPage> createState() => _FormExercicioPageState();
}

class _FormExercicioPageState extends State<FormExercicioPage> {
  final _formKey = GlobalKey<FormState>();

  final nome = TextEditingController();
  final series = TextEditingController();
  final repeticoes = TextEditingController();
  final carga = TextEditingController();
  final observacoes = TextEditingController();

  String grupoMuscular = "Peito";
  String equipamento = "Halteres";

  final grupos = [
    "Peito",
    "Costas",
    "Ombros",
    "Bíceps",
    "Tríceps",
    "Quadríceps",
    "Glúteos",
    "Posterior"
  ];

  final equipamentos = [
    "Halteres",
    "Barra",
    "Máquina",
    "Cabo",
    "Peso corporal"
  ];

  CollectionReference get exerciciosCollection => FirebaseFirestore.instance
      .collection('rotinas')
      .doc(widget.uid)
      .collection('minhas_rotinas')
      .doc(widget.rotinaId)
      .collection('exercicios');

  @override
  void initState() {
    super.initState();
    if (widget.exercicio != null) {
      final ex = widget.exercicio!;
      nome.text = ex.nome;
      series.text = ex.series.toString();
      repeticoes.text = ex.repeticoes.toString();
      carga.text = ex.carga.toString();
      grupoMuscular = ex.grupoMuscular;
      equipamento = ex.tipoEquipamento;
      observacoes.text = ex.observacoes ?? '';
    }
  }


  Future<void> salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'nome': nome.text.trim(),
      'grupoMuscular': grupoMuscular,
      'tipoEquipamento': equipamento,
      'series': int.parse(series.text.trim()),
      'repeticoes': int.parse(repeticoes.text.trim()),
      'carga': double.parse(carga.text.trim()),
      'observacoes': observacoes.text.trim(),
      'createdAt': Timestamp.now(),
    };

    try {
      if (widget.exercicio == null) {
        // Criar novo exercício
        await exerciciosCollection.add(dados);
      } else {
        // Atualizar exercício existente
        await exerciciosCollection.doc(widget.exercicio!.id).update(dados);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercicio == null ? "Novo Exercício" : "Editar Exercício"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nome
              TextFormField(
                controller: nome,
                decoration: const InputDecoration(labelText: "Nome do exercício"),
                validator: (v) => v!.isEmpty ? "Informe um nome" : null,
              ),
              const SizedBox(height: 10),

              // Grupo Muscular
              DropdownButtonFormField(
                value: grupoMuscular,
                items: grupos
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => grupoMuscular = v!),
                decoration: const InputDecoration(labelText: "Grupo Muscular"),
              ),
              const SizedBox(height: 10),

              // Equipamento
              DropdownButtonFormField(
                value: equipamento,
                items: equipamentos
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => equipamento = v!),
                decoration: const InputDecoration(labelText: "Equipamento"),
              ),
              const SizedBox(height: 10),

              // Séries, Repetições, Carga
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: series,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Séries"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Informe o número de séries";
                        final valor = double.tryParse(v);
                        if (valor == null) return "Use apenas números (ex: 10.5)";
                        if (valor > 50) return "Insira uma carga válida";
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: repeticoes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Repetições"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Informe as repetições";
                        final valor = double.tryParse(v);
                        if (valor == null) return "Use apenas números (ex: 10.5)";
                        switch (grupoMuscular){
                          case "Peito":
                          case "Costas":
                          case "Bíceps":
                          case "Tríceps":
                          case "Ombros":
                          if(valor > 50){
                            return "Insira uma carga válida";
                          }
                          case "Quadríceps":
                          case "Glúteos":
                          case "Posterior":
                          if(valor > 200){
                            return "Insira uma carga válida";
                          }
                        };
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: carga,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Carga (kg)"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Informe a carga";
                        final valor = double.tryParse(v);
                        if (valor == null) return "Use apenas números (ex: 10.5)";
                        switch (grupoMuscular){
                          case "Peito":
                          case "Costas":
                          if(valor > 300){
                            return "Insira uma carga válida";
                          }
                          case "Bíceps":
                          case "Tríceps":
                          case "Ombros":
                          if(valor > 200){
                            return "Insira uma carga válida";
                          }
                          case "Quadríceps":
                          case "Glúteos":
                          case "Posterior":
                          if(valor > 2000){
                            return "Insira uma carga válida";
                          }
                        };
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Observações
              TextFormField(
                controller: observacoes,
                decoration: const InputDecoration(
                  labelText: "Observações",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.multiline,
                minLines: 3,
                maxLines: null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Salvar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
