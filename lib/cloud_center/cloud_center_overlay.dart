import 'package:app_cloud/app_cloud.dart';
import 'package:flutter/material.dart';
import 'package:game_widgets_cloud_center/game_widgets_cloud_center.dart';

import 'cloud_center_session.dart';

class CloudCenterOverlay extends StatelessWidget {
  final CloudCenterSession session;
  const CloudCenterOverlay({super.key, required this.session});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) {
      if (!session.isOpen) return const SizedBox.shrink();
      if (session.configuring) return _Setup(session: session);
      if (session.cubit == null) {
        return const Stack(
          children: [
            ModalBarrier(dismissible: false, color: Colors.black54),
            Center(child: CircularProgressIndicator()),
          ],
        );
      }
      return CloudCenterPanel(
        cubit: session.cubit!,
        mode: session.mode!,
        onClose: session.closePanel,
        onConfigure: session.showConfiguration,
      );
    },
  );
}

class _Setup extends StatefulWidget {
  final CloudCenterSession session;
  const _Setup({required this.session});
  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  final _backend = TextEditingController();
  final _context = TextEditingController();
  final _token = TextEditingController();
  CloudMode _mode = CloudMode.real;
  bool _loopback = false;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _backend.text = widget.session.backendUrl;
    _context.text = widget.session.authContext;
    _mode = widget.session.mode ?? CloudMode.real;
  }

  @override
  void dispose() {
    _backend.dispose();
    _context.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.session.configure(
        mode: _mode,
        backendUrl: _backend.text,
        authContext: _context.text,
        appToken: _token.text,
        allowLoopbackHttp: _loopback,
      );
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is CloudFailure ? e.message : 'Use a valid HTTPS backend URL, authorization context and application token.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: ModalBarrier(dismissible: false, color: Colors.black54),
      ),
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Cloud Center connection',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: _saving ? null : widget.session.closePanel,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Text(
                      'Real mode reads your self-hosted backend. Provider credentials are configured on the server.',
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<CloudMode>(
                      segments: const [
                        ButtonSegment(
                          value: CloudMode.real,
                          label: Text('Real backend'),
                        ),
                        ButtonSegment(
                          value: CloudMode.demo,
                          label: Text('Demo'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _saving
                          ? null
                          : (selection) =>
                                setState(() => _mode = selection.single),
                    ),
                    if (_mode == CloudMode.demo)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'DEMO · Synthetic data. No cloud account is contacted.',
                        ),
                      ),
                    if (_mode == CloudMode.real) ...[
                      TextField(
                        controller: _backend,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Backend URL (https://…)',
                        ),
                      ),
                      TextField(
                        controller: _context,
                        decoration: const InputDecoration(
                          labelText: 'Authorization context / profile name',
                        ),
                      ),
                      TextField(
                        controller: _token,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Application access token',
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _loopback,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _loopback = v ?? false),
                        title: const Text(
                          'Development: allow localhost HTTP this session',
                        ),
                      ),
                    ],
                    if (widget.session.configurationError != null)
                      Text(widget.session.configurationError!),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _saving ? 'Saving…' : 'Save and return to room',
                      ),
                    ),
                    if (widget.session.repository != null)
                      TextButton(
                        onPressed: _saving ? null : widget.session.signOut,
                        child: const Text(
                          'Disconnect and clear cached session',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
