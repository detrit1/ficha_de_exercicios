import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ficha_de_exercicios/view/rotina_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    final rotinaCollection = FirebaseFirestore.instance
        .collection('rotinas')
        .doc(uid)
        .collection('minhas_rotinas');

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Minhas Rotinas", style: const TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple[400],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            rotinaCollection.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rotinas = snapshot.data!.docs;

          if (rotinas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note, // ícone de rotina/planejamento
                    size: 80,
                    color: Colors.purple[300],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Ops! Nenhuma rotina ainda…",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Clique no + para criar sua primeira rotina e começar a planejar seus treinos!",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }


          return Center(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: rotinas.length,
              itemBuilder: (context, index) {
                final rotina = rotinas[index];

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Dismissible(
                    key: Key(rotina.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF2C2C2C),
                          title: const Text(
                            'Confirmar exclusão',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            'Deseja realmente excluir esta rotina?',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 255, 112, 112),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Excluir', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) async {
                      await rotinaCollection.doc(rotina.id).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('${rotina['nome']} excluída com sucesso')),
                      );
                    },
                    child: SizedBox(
                      height: 90,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RotinaPage(
                                rotinaId: rotina.id,
                                rotinaNome: rotina['nome'],
                                uid: uid,
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            rotina['nome'] ?? 'Sem nome',
                            style: const TextStyle(
                              color: const Color(0xFF2C2C2C),
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2C2C2C),
        onPressed: () => _criarNovaRotina(context, rotinaCollection),
        child: const Icon(Icons.add, color: Colors.purple),
      ),
    );
  }

  void _criarNovaRotina(
      BuildContext context, CollectionReference rotinaCollection) {
    final nomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Nova Rotina", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nomeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Nome da rotina",
            labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            filled: true,
            fillColor: Color(0xFF1E1E1E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
            ),
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isNotEmpty) {
                await rotinaCollection.add({
                  'nome': nome,
                  'createdAt': Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Criar", style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),),
          ),
        ],
      ),
    );
  }
}
