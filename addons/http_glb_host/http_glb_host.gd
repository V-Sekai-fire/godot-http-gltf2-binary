# Copyright (c) 2025-present. This file is part of V-Sekai https://v-sekai.org/.
# K. S. Ernest (Fire) Lee & Contributors
# http_glb_host.gd
# SPDX-License-Identifier: MIT

@tool
extends EditorPlugin

var http_server: TCPServer
const PORT = 8080
var MSFT_texture_dds: GLTFDocumentExtension = null
var compatible: bool = false

func _enter_tree():
	MSFT_texture_dds = preload("res://addons/http_glb_host/MSFT_texture_dds.gd").new()
	GLTFDocument.register_gltf_document_extension(MSFT_texture_dds)
	print("MSFT_texture_dds extension loaded.")
	print(GLTFDocument.get_supported_gltf_extensions())
	http_server = TCPServer.new()
	var err_http: Error = http_server.listen(PORT)
	if err_http != OK:
		push_error("HTTP Server start error: " + str(err_http))
		return

func _exit_tree():
	if MSFT_texture_dds:
		GLTFDocument.unregister_gltf_document_extension(MSFT_texture_dds)
	if not http_server:
		return
	http_server.stop()
	http_server = null

func _process(delta):
	if http_server == null:
		return
	if not http_server.is_connection_available():
		return
	
	var http_client: StreamPeerTCP = http_server.take_connection()
	if http_client == null:
		return
	
	var request: String = ""
	if http_client.get_available_bytes() > 0:
		request = http_client.get_utf8_string(http_client.get_available_bytes()).strip_edges()
	else:
		http_client.disconnect_from_host()
		return
	
	if not request.begins_with("GET "):
		send_bad_request(http_client, "Invalid request.")
		return
	
	var path_end = request.find(" HTTP/")
	if path_end == -1:
		path_end = request.length()
	
	var full_path = request.substr(4, path_end - 4).strip_edges()
	var query_string = ""
	var path = full_path
	
	if full_path.find("?") != -1:
		var parts = full_path.split("?", false, 2)
		path = parts[0]
		query_string = parts[1]
	
	compatible = query_string.find("compatible") != -1
	var glb_data: PackedByteArray = PackedByteArray()
	
	if path.is_empty() or path == "/":
		var gltf_doc = GLTFDocument.new()
		gltf_doc.image_format = "PNG"
		if compatible and MSFT_texture_dds:
			gltf_doc.image_format = "DDS" 
		var state = GLTFState.new()
		var flags = EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS | EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS
		var error = gltf_doc.append_from_scene(get_editor_interface().get_edited_scene_root(), state, flags)
		if error != OK:
			push_error("GLTF export error: " + str(error))
			return
		glb_data = gltf_doc.generate_buffer(state)
	else:
		send_bad_request(http_client, "Invalid path.")
		return
	
	if glb_data.size() > 0:
		var response = "HTTP/1.1 200 OK\r\nContent-Type: model/gltf-binary\r\nContent-Disposition: attachment; filename=\"model.glb\"\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % glb_data.size()
		http_client.put_data(response.to_utf8_buffer())
		http_client.put_data(glb_data)
	else:
		send_not_found(http_client, "GLB data not available.")
	
	http_client.disconnect_from_host()

func send_bad_request(client, message):
	var error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n" + message
	client.put_data(error_response.to_utf8_buffer())
	client.disconnect_from_host()

func send_not_found(client, message):
	var error_response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n" + message
	client.put_data(error_response.to_utf8_buffer())
	client.disconnect_from_host()
