import Foundation

struct Localization {
    static let currentLanguage: AppLanguage = {
        AppLanguage(rawValue: ConfigManager.shared.appLanguageRawValue) ?? .english
    }()
    
    static let strings: [AppLanguage: LocalizationStrings] = [
        .english: LocalizationStrings(
            appName: "Cognitive Ether",
            chat: "Chat",
            models: "Models",
            monitor: "Monitor",
            tools: "Tools",
            prompts: "Prompts",
            settings: "Settings",
            history: "History",
            newConversation: "New Conversation",
            sendMessage: "Message Cognitive Ether...",
            generating: "Generating response...",
            thinking: "Thinking",
            noProvider: "No provider configured",
            welcomeMessage: "Welcome to Cognitive Ether. Your conversations are now persisted locally, so we can continue where we left off.",
            providerRouting: "Provider Routing",
            preferredProvider: "Preferred Provider",
            requestTuning: "Request Tuning",
            temperature: "Temperature",
            topP: "Top-P",
            contextWindow: "Context Window",
            servicesCredentials: "Services & Credentials",
            openAIKey: "OpenAI API Key",
            deepSeekKey: "DeepSeek API Key",
            geminiKey: "Gemini API Key",
            huggingFaceToken: "Hugging Face Token",
            ollamaEndpoint: "Ollama Endpoint",
            enableOllama: "Enable Ollama",
            providerDiagnostics: "Provider Diagnostics",
            refreshDiagnostics: "Refresh Provider Diagnostics",
            refreshing: "Refreshing...",
            behavior: "Behavior",
            defaultSystemPrompt: "Default System Prompt",
            crossSessionMemory: "Cross-session Memory",
            webBrowsing: "Web Browsing",
            resetPrompt: "Reset Prompt",
            localData: "Local Data",
            clearConversations: "Clear Saved Conversations",
            modelExplorer: "Model Explorer",
            currentRouting: "Current Routing",
            localModels: "Ollama Local Models",
            recommendedDownloads: "Recommended Downloads",
            cloudProviders: "Cloud Providers",
            selectedForChat: "Selected for Chat",
            useInChat: "Use in Chat",
            capabilities: "Capabilities",
            runtimeStatus: "Runtime Status",
            operationalFeatures: "Operational Features",
            promptGallery: "Prompt Gallery",
            currentPrompt: "Current System Prompt",
            presetLibrary: "Preset Library",
            applyPreset: "Apply Preset",
            customPrompts: "Custom Prompts",
            createPrompt: "Create Prompt",
            promptTitle: "Prompt Title",
            promptContent: "Prompt Content",
            save: "Save",
            cancel: "Cancel",
            delete: "Delete",
            edit: "Edit",
            copy: "Copy",
            search: "Search",
            searchPresets: "Search presets...",
            searchConversations: "Search conversations...",
            sessions: "Sessions",
            messages: "Messages",
            acrossAllChats: "Across all chats",
            savedSessions: "Saved Sessions",
            active: "Active",
            resume: "Resume",
            rename: "Rename",
            copyTranscript: "Copy Transcript",
            export: "Export",
            clear: "Clear",
            resourceMonitor: "Resource Monitor",
            inferenceMetrics: "Inference Metrics",
            thermalState: "Thermal State",
            nominal: "Nominal",
            fair: "Fair",
            serious: "Serious",
            critical: "Critical",
            language: "Language",
            webSearch: "Web Search",
            webSearchEndpoint: "SearXNG Endpoint",
            webSearchHint: "Enter a SearXNG instance URL to enable web search"
        ),
        .spanish: LocalizationStrings(
            appName: "Cognitive Ether",
            chat: "Chat",
            models: "Modelos",
            monitor: "Monitor",
            tools: "Herramientas",
            prompts: "Prompts",
            settings: "Configuración",
            history: "Historial",
            newConversation: "Nueva Conversación",
            sendMessage: "Escribe un mensaje...",
            generating: "Generando respuesta...",
            thinking: "Pensando",
            noProvider: "Ningún proveedor configurado",
            welcomeMessage: "Bienvenido a Cognitive Ether. Tus conversaciones se guardan localmente para continuar donde las dejaste.",
            providerRouting: "Enrutamiento de Proveedor",
            preferredProvider: "Proveedor Preferido",
            requestTuning: "Ajuste de Solicitudes",
            temperature: "Temperatura",
            topP: "Top-P",
            contextWindow: "Ventana de Contexto",
            servicesCredentials: "Servicios y Credenciales",
            openAIKey: "Clave API de OpenAI",
            deepSeekKey: "Clave API de DeepSeek",
            geminiKey: "Clave API de Gemini",
            huggingFaceToken: "Token de Hugging Face",
            ollamaEndpoint: "Endpoint de Ollama",
            enableOllama: "Habilitar Ollama",
            providerDiagnostics: "Diagnósticos de Proveedor",
            refreshDiagnostics: "Actualizar Diagnósticos",
            refreshing: "Actualizando...",
            behavior: "Comportamiento",
            defaultSystemPrompt: "Prompt del Sistema por Defecto",
            crossSessionMemory: "Memoria entre Sesiones",
            webBrowsing: "Navegación Web",
            resetPrompt: "Restablecer Prompt",
            localData: "Datos Locales",
            clearConversations: "Borrar Conversaciones Guardadas",
            modelExplorer: "Explorador de Modelos",
            currentRouting: "Enrutamiento Actual",
            localModels: "Modelos Locales de Ollama",
            recommendedDownloads: "Descargas Recomendadas",
            cloudProviders: "Proveedores en la Nube",
            selectedForChat: "Seleccionado para Chat",
            useInChat: "Usar en Chat",
            capabilities: "Capacidades",
            runtimeStatus: "Estado del Sistema",
            operationalFeatures: "Características Operativas",
            promptGallery: "Galería de Prompts",
            currentPrompt: "Prompt Actual del Sistema",
            presetLibrary: "Biblioteca de Presets",
            applyPreset: "Aplicar Preset",
            customPrompts: "Prompts Personalizados",
            createPrompt: "Crear Prompt",
            promptTitle: "Título del Prompt",
            promptContent: "Contenido del Prompt",
            save: "Guardar",
            cancel: "Cancelar",
            delete: "Eliminar",
            edit: "Editar",
            copy: "Copiar",
            search: "Buscar",
            searchPresets: "Buscar presets...",
            searchConversations: "Buscar conversaciones...",
            sessions: "Sesiones",
            messages: "Mensajes",
            acrossAllChats: "En todos los chats",
            savedSessions: "Sesiones Guardadas",
            active: "Activo",
            resume: "Continuar",
            rename: "Renombrar",
            copyTranscript: "Copiar Transcripción",
            export: "Exportar",
            clear: "Borrar",
            resourceMonitor: "Monitor de Recursos",
            inferenceMetrics: "Métricas de Inferencia",
            thermalState: "Estado Térmico",
            nominal: "Nominal",
            fair: "Aceptable",
            serious: "Serio",
            critical: "Crítico",
            language: "Idioma",
            webSearch: "Búsqueda Web",
            webSearchEndpoint: "Endpoint de SearXNG",
            webSearchHint: "Introduce una URL de instancia SearXNG para habilitar la búsqueda web"
        ),
        .portuguese: LocalizationStrings(
            appName: "Cognitive Ether",
            chat: "Chat",
            models: "Modelos",
            monitor: "Monitor",
            tools: "Ferramentas",
            prompts: "Prompts",
            settings: "Configurações",
            history: "Histórico",
            newConversation: "Nova Conversa",
            sendMessage: "Digite uma mensagem...",
            generating: "Gerando resposta...",
            thinking: "Pensando",
            noProvider: "Nenhum provedor configurado",
            welcomeMessage: "Bem-vindo ao Cognitive Ether. Suas conversas são salvas localmente para continuar de onde parou.",
            providerRouting: "Roteamento de Provedor",
            preferredProvider: "Provedor Preferido",
            requestTuning: "Ajuste de Solicitações",
            temperature: "Temperatura",
            topP: "Top-P",
            contextWindow: "Janela de Contexto",
            servicesCredentials: "Serviços e Credenciais",
            openAIKey: "Chave API do OpenAI",
            deepSeekKey: "Chave API do DeepSeek",
            geminiKey: "Chave API do Gemini",
            huggingFaceToken: "Token do Hugging Face",
            ollamaEndpoint: "Endpoint do Ollama",
            enableOllama: "Habilitar Ollama",
            providerDiagnostics: "Diagnósticos de Provedor",
            refreshDiagnostics: "Atualizar Diagnósticos",
            refreshing: "Atualizando...",
            behavior: "Comportamento",
            defaultSystemPrompt: "Prompt do Sistema Padrão",
            crossSessionMemory: "Memória entre Sessões",
            webBrowsing: "Navegação Web",
            resetPrompt: "Redefinir Prompt",
            localData: "Dados Locais",
            clearConversations: "Limpar Conversas Salvas",
            modelExplorer: "Explorador de Modelos",
            currentRouting: "Roteamento Atual",
            localModels: "Modelos Locais do Ollama",
            recommendedDownloads: "Downloads Recomendados",
            cloudProviders: "Provedores de Nuvem",
            selectedForChat: "Selecionado para Chat",
            useInChat: "Usar no Chat",
            capabilities: "Capacidades",
            runtimeStatus: "Status do Sistema",
            operationalFeatures: "Recursos Operacionais",
            promptGallery: "Galeria de Prompts",
            currentPrompt: "Prompt Atual do Sistema",
            presetLibrary: "Biblioteca de Presets",
            applyPreset: "Aplicar Preset",
            customPrompts: "Prompts Personalizados",
            createPrompt: "Criar Prompt",
            promptTitle: "Título do Prompt",
            promptContent: "Conteúdo do Prompt",
            save: "Salvar",
            cancel: "Cancelar",
            delete: "Excluir",
            edit: "Editar",
            copy: "Copiar",
            search: "Buscar",
            searchPresets: "Buscar presets...",
            searchConversations: "Buscar conversas...",
            sessions: "Sessões",
            messages: "Mensagens",
            acrossAllChats: "Em todos os chats",
            savedSessions: "Sessões Salvas",
            active: "Ativo",
            resume: "Continuar",
            rename: "Renomear",
            copyTranscript: "Copiar Transcrição",
            export: "Exportar",
            clear: "Limpar",
            resourceMonitor: "Monitor de Recursos",
            inferenceMetrics: "Métricas de Inferência",
            thermalState: "Estado Térmico",
            nominal: "Nominal",
            fair: "Aceitável",
            serious: "Sério",
            critical: "Crítico",
            language: "Idioma",
            webSearch: "Pesquisa Web",
            webSearchEndpoint: "Endpoint do SearXNG",
            webSearchHint: "Insira uma URL de instância SearXNG para ativar a pesquisa na web"
        )
    ]
    
    static func string(_ key: String) -> String {
        return strings[currentLanguage]?.string(key: key) ?? strings[.english]?.string(key: key) ?? key
    }
    
    static var appName: String { string(LocalizationKeys.appName) }
    static var chat: String { string(LocalizationKeys.chat) }
    static var models: String { string(LocalizationKeys.models) }
    static var monitor: String { string(LocalizationKeys.monitor) }
    static var tools: String { string(LocalizationKeys.tools) }
    static var prompts: String { string(LocalizationKeys.prompts) }
    static var settings: String { string(LocalizationKeys.settings) }
    static var history: String { string(LocalizationKeys.history) }
    static var newConversation: String { string(LocalizationKeys.newConversation) }
    static var sendMessage: String { string(LocalizationKeys.sendMessage) }
    static var generating: String { string(LocalizationKeys.generating) }
    static var thinking: String { string(LocalizationKeys.thinking) }
}

struct LocalizationStrings: Codable {
    let appName: String
    let chat: String
    let models: String
    let monitor: String
    let tools: String
    let prompts: String
    let settings: String
    let history: String
    let newConversation: String
    let sendMessage: String
    let generating: String
    let thinking: String
    let noProvider: String
    let welcomeMessage: String
    let providerRouting: String
    let preferredProvider: String
    let requestTuning: String
    let temperature: String
    let topP: String
    let contextWindow: String
    let servicesCredentials: String
    let openAIKey: String
    let deepSeekKey: String
    let geminiKey: String
    let huggingFaceToken: String
    let ollamaEndpoint: String
    let enableOllama: String
    let providerDiagnostics: String
    let refreshDiagnostics: String
    let refreshing: String
    let behavior: String
    let defaultSystemPrompt: String
    let crossSessionMemory: String
    let webBrowsing: String
    let resetPrompt: String
    let localData: String
    let clearConversations: String
    let modelExplorer: String
    let currentRouting: String
    let localModels: String
    let recommendedDownloads: String
    let cloudProviders: String
    let selectedForChat: String
    let useInChat: String
    let capabilities: String
    let runtimeStatus: String
    let operationalFeatures: String
    let promptGallery: String
    let currentPrompt: String
    let presetLibrary: String
    let applyPreset: String
    let customPrompts: String
    let createPrompt: String
    let promptTitle: String
    let promptContent: String
    let save: String
    let cancel: String
    let delete: String
    let edit: String
    let copy: String
    let search: String
    let searchPresets: String
    let searchConversations: String
    let sessions: String
    let messages: String
    let acrossAllChats: String
    let savedSessions: String
    let active: String
    let resume: String
    let rename: String
    let copyTranscript: String
    let export: String
    let clear: String
    let resourceMonitor: String
    let inferenceMetrics: String
    let thermalState: String
    let nominal: String
    let fair: String
    let serious: String
    let critical: String
    let language: String
    let webSearch: String
    let webSearchEndpoint: String
    let webSearchHint: String
    
    func string(key: String) -> String {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if child.label == key {
                return child.value as? String ?? key
            }
        }
        return key
    }
}

struct LocalizationKeys {
    static let appName = "appName"
    static let chat = "chat"
    static let models = "models"
    static let monitor = "monitor"
    static let tools = "tools"
    static let prompts = "prompts"
    static let settings = "settings"
    static let history = "history"
    static let newConversation = "newConversation"
    static let sendMessage = "sendMessage"
    static let generating = "generating"
    static let thinking = "thinking"
    static let noProvider = "noProvider"
    static let welcomeMessage = "welcomeMessage"
    static let providerRouting = "providerRouting"
    static let preferredProvider = "preferredProvider"
    static let requestTuning = "requestTuning"
    static let temperature = "temperature"
    static let topP = "topP"
    static let contextWindow = "contextWindow"
    static let servicesCredentials = "servicesCredentials"
    static let openAIKey = "openAIKey"
    static let deepSeekKey = "deepSeekKey"
    static let geminiKey = "geminiKey"
    static let huggingFaceToken = "huggingFaceToken"
    static let ollamaEndpoint = "ollamaEndpoint"
    static let enableOllama = "enableOllama"
    static let providerDiagnostics = "providerDiagnostics"
    static let refreshDiagnostics = "refreshDiagnostics"
    static let refreshing = "refreshing"
    static let behavior = "behavior"
    static let defaultSystemPrompt = "defaultSystemPrompt"
    static let crossSessionMemory = "crossSessionMemory"
    static let webBrowsing = "webBrowsing"
    static let resetPrompt = "resetPrompt"
    static let localData = "localData"
    static let clearConversations = "clearConversations"
    static let modelExplorer = "modelExplorer"
    static let currentRouting = "currentRouting"
    static let localModels = "localModels"
    static let recommendedDownloads = "recommendedDownloads"
    static let cloudProviders = "cloudProviders"
    static let selectedForChat = "selectedForChat"
    static let useInChat = "useInChat"
    static let capabilities = "capabilities"
    static let runtimeStatus = "runtimeStatus"
    static let operationalFeatures = "operationalFeatures"
    static let promptGallery = "promptGallery"
    static let currentPrompt = "currentPrompt"
    static let presetLibrary = "presetLibrary"
    static let applyPreset = "applyPreset"
    static let customPrompts = "customPrompts"
    static let createPrompt = "createPrompt"
    static let promptTitle = "promptTitle"
    static let promptContent = "promptContent"
    static let save = "save"
    static let cancel = "cancel"
    static let delete = "delete"
    static let edit = "edit"
    static let copy = "copy"
    static let search = "search"
    static let searchPresets = "searchPresets"
    static let searchConversations = "searchConversations"
    static let sessions = "sessions"
    static let messages = "messages"
    static let acrossAllChats = "acrossAllChats"
    static let savedSessions = "savedSessions"
    static let active = "active"
    static let resume = "resume"
    static let rename = "rename"
    static let copyTranscript = "copyTranscript"
    static let export = "export"
    static let clear = "clear"
    static let resourceMonitor = "resourceMonitor"
    static let inferenceMetrics = "inferenceMetrics"
    static let thermalState = "thermalState"
    static let nominal = "nominal"
    static let fair = "fair"
    static let serious = "serious"
    static let critical = "critical"
    static let language = "language"
    static let webSearch = "webSearch"
    static let webSearchEndpoint = "webSearchEndpoint"
    static let webSearchHint = "webSearchHint"
}