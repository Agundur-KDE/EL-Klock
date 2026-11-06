find_package(Qt6 REQUIRED COMPONENTS Core Qml)

include(ECMQmlModule)

ecm_add_qml_module(elklockplugin
    URI de.agundur.elklock
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
)

target_sources(elklockplugin PRIVATE
    FileReader.cpp FileReader.h
)

target_link_libraries(elklockplugin PRIVATE Qt6::Core Qt6::Qml)

ecm_finalize_qml_module(elklockplugin)
