extends RefCounted

var _server := TCPServer.new()

func acquire(data_directory: String) -> bool:
	if _server.is_listening():
		return true
	# A loopback bind is an OS-held lifetime lock; no external traffic or daemon.
	# A collision fails closed, preventing concurrent writers and data loss.
	var scope := ProjectSettings.globalize_path(data_directory).simplify_path().to_lower()
	var port := 40000 + posmod(scope.hash(), 20000)
	return _server.listen(port, "127.0.0.1") == OK

func release() -> void:
	_server.stop()
