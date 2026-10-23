
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    const lilas = Color(0xFF9575CD);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Perfil com Foto e Localização',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: lilas,
          primary: lilas,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lilas,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F5FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFE4D9F8),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: lilas,
              width: 2,
            ),
          ),
        ),
      ),
      home: const TelaPerfil(),
    );
  }
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  static const Color lilas = Color(0xFF9575CD);
  static const Color lilasEscuro = Color(0xFF6741A5);
  static const Color lilasClaro = Color(0xFFEDE7F6);
  static const Color fundo = Color(0xFFF8F5FF);

  final ImagePicker picker = ImagePicker();
  final TextEditingController nomeController = TextEditingController();

  File? foto;

  String nome = '';
  String localizacao = 'Sua localização ainda não foi obtida.';
  String ultimaAtualizacao = '';

  bool localizacaoObtida = false;
  bool buscandoLocalizacao = false;

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  Future<void> escolherFoto(ImageSource origem) async {
    try {
      final XFile? imagem = await picker.pickImage(
        source: origem,
        imageQuality: 85,
      );

      if (imagem != null && mounted) {
        setState(() {
          foto = File(imagem.path);
        });
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a imagem.'),
        ),
      );
    }
  }

  void mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Foto de perfil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: lilasEscuro,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: lilasEscuro,
                  ),
                  title: const Text('Tirar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    escolherFoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: lilasEscuro,
                  ),
                  title: const Text('Escolher da galeria'),
                  onTap: () {
                    Navigator.pop(context);
                    escolherFoto(ImageSource.gallery);
                  },
                ),
                if (foto != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Remover foto'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        foto = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> obterLocalizacao() async {
    setState(() {
      buscandoLocalizacao = true;
      localizacao = 'Obtendo sua localização...';
    });

    try {
      final bool servicoAtivo =
          await Geolocator.isLocationServiceEnabled();

      if (!servicoAtivo) {
        atualizarErroLocalizacao(
          'Ative o GPS do dispositivo e tente novamente.',
        );
        return;
      }

      LocationPermission permissao =
          await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        atualizarErroLocalizacao(
          'Permissão de localização negada.',
        );
        return;
      }

      if (permissao == LocationPermission.deniedForever) {
        atualizarErroLocalizacao(
          'Permissão negada permanentemente. '
          'Libere o acesso nas configurações.',
        );
        return;
      }

      final Position posicao =
          await Geolocator.getCurrentPosition();

      if (!mounted) return;

      final DateTime agora = DateTime.now();

      final String data =
          '${agora.day.toString().padLeft(2, '0')}/'
          '${agora.month.toString().padLeft(2, '0')}/'
          '${agora.year} às '
          '${agora.hour.toString().padLeft(2, '0')}:'
          '${agora.minute.toString().padLeft(2, '0')}';

      setState(() {
        localizacao =
            'Latitude: ${posicao.latitude.toStringAsFixed(4)}\n'
            'Longitude: ${posicao.longitude.toStringAsFixed(4)}';

        localizacaoObtida = true;
        buscandoLocalizacao = false;
        ultimaAtualizacao = data;
      });
    } catch (_) {
      atualizarErroLocalizacao(
        'Não foi possível obter a localização. Tente novamente.',
      );
    }
  }

  void atualizarErroLocalizacao(String mensagem) {
    if (!mounted) return;

    setState(() {
      localizacao = mensagem;
      localizacaoObtida = false;
      buscandoLocalizacao = false;
    });
  }

  Widget criarBotaoFoto({
    required IconData icone,
    required String texto,
    required VoidCallback aoPressionar,
    bool principal = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: principal
          ? ElevatedButton.icon(
              onPressed: aoPressionar,
              icon: Icon(icone),
              label: Text(texto),
              style: ElevatedButton.styleFrom(
                backgroundColor: lilas,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: aoPressionar,
              icon: Icon(icone),
              label: Text(texto),
              style: OutlinedButton.styleFrom(
                foregroundColor: lilasEscuro,
                side: const BorderSide(color: lilas),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              const Icon(
                Icons.account_circle_outlined,
                size: 42,
                color: lilasEscuro,
              ),

              const SizedBox(height: 8),

              const Text(
                'Bem-vindo(a)!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: lilasEscuro,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Personalize seu perfil e consulte sua localização.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: lilas.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: lilasClaro,
                          backgroundImage: foto != null
                              ? FileImage(foto!)
                              : null,
                          child: foto == null
                              ? const Icon(
                                  Icons.person_outline,
                                  size: 72,
                                  color: lilasEscuro,
                                )
                              : null,
                        ),
                        Material(
                          color: lilas,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: mostrarOpcoesFoto,
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(11),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 21,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextButton.icon(
                      onPressed: mostrarOpcoesFoto,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Alterar foto'),
                      style: TextButton.styleFrom(
                        foregroundColor: lilasEscuro,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Seu nome',
                        hintText: 'Digite seu nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (valor) {
                        setState(() {
                          nome = valor.trim();
                        });
                      },
                    ),

                    if (nome.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Olá, $nome!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: lilasEscuro,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    criarBotaoFoto(
                      icone: Icons.camera_alt_outlined,
                      texto: 'Tirar foto',
                      aoPressionar: () =>
                          escolherFoto(ImageSource.camera),
                      principal: true,
                    ),

                    const SizedBox(height: 10),

                    criarBotaoFoto(
                      icone: Icons.photo_library_outlined,
                      texto: 'Escolher da galeria',
                      aoPressionar: () =>
                          escolherFoto(ImageSource.gallery),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: localizacaoObtida
                        ? const Color(0xFF81C784)
                        : lilasClaro,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: lilas.withValues(alpha: 0.07),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        color: fundo,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        localizacaoObtida
                            ? Icons.location_on
                            : Icons.location_searching,
                        size: 36,
                        color: localizacaoObtida
                            ? Colors.green
                            : lilasEscuro,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Minha localização',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: lilasEscuro,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      localizacaoObtida
                          ? 'Localização obtida com sucesso!'
                          : 'Ative o GPS e toque no botão para '
                              'consultar as coordenadas.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: fundo,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        localizacao,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: lilasEscuro,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.8,
                        ),
                      ),
                    ),

                    if (ultimaAtualizacao.isNotEmpty &&
                        localizacaoObtida) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Última atualização: $ultimaAtualizacao',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: buscandoLocalizacao
                            ? null
                            : obterLocalizacao,
                        icon: buscandoLocalizacao
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                localizacaoObtida
                                    ? Icons.refresh
                                    : Icons.my_location,
                              ),
                        label: Text(
                          buscandoLocalizacao
                              ? 'Obtendo localização...'
                              : localizacaoObtida
                                  ? 'Atualizar localização'
                                  : 'Usar minha localização',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lilas,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              lilas.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: lilasEscuro,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'A localização só é solicitada quando '
                      'você toca no botão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: lilasEscuro,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
