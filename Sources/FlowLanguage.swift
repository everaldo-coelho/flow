import SwiftUI

final class FlowLanguageSettings: ObservableObject {
    static let shared = FlowLanguageSettings()
    @Published var code: String = LampStore.load(String.self, from: "appLanguage") ?? "en" {
        didSet { LampStore.save(code, to: "appLanguage") }
    }
    static let choices = [("en", "English"), ("pt-BR", "Português (Brasil)"), ("es", "Español")]
    var locale: Locale { Locale(identifier: code == "en" ? "en_BR" : code) }
}
enum FlowL {
    static func format(_ key: String, _ values: String...) -> String {
        String(format: text(key), arguments: values)
    }
    static func text(_ key: String) -> String {
        guard let values = translations[key] else { return key }
        switch FlowLanguageSettings.shared.code {
        case "pt-BR": return values[0]
        case "es": return values[1]
        default: return key
        }
    }
    static var aiInstruction: String {
        let language = FlowLanguageSettings.shared.code == "pt-BR" ? "Brazilian Portuguese" : FlowLanguageSettings.shared.code == "es" ? "Spanish" : "English (Brazil)"
        return " Write all user-visible responses, task titles, steps, explanations and email prose in \(language). Keep JSON property names, enum values and IDs exactly as the requested schema specifies. Do not translate quoted evidence."
    }
    private static let translations: [String: [String]] = {
        let rows = """
Today|Hoje|Hoy
View task|Ver tarefa|Ver tarea
Habit occurrences completed|Repetições concluídas|Repeticiones completadas
Appearance, focus and preferences. At your pace.|Aparência, foco e preferências. No seu ritmo.|Apariencia, enfoque y preferencias. A tu ritmo.
Tasks, projects, habit history and achievements are saved locally on this Mac.|Tarefas, projetos, histórico de hábitos e conquistas ficam salvos neste Mac.|Las tareas, proyectos, historial de hábitos y logros se guardan en este Mac.
Capture and AI privacy|Captura e privacidade da IA|Captura y privacidad de IA
Capture accepts typing, audio and files. AI suggests tasks; you decide what to save. Processed file copies are removed. Your originals stay where they are. Ask FLOW includes your tasks only when you enable that option.|Capture digitando, gravando áudio ou adicionando arquivos. A IA sugere tarefas; você decide o que salvar. As cópias processadas dos arquivos são removidas. Seus originais continuam onde estão. Ask FLOW inclui suas tarefas somente quando você ativa essa opção.|Captura texto, audio o archivos. La IA sugiere tareas; tú decides qué guardar. Se eliminan las copias procesadas de los archivos. Los originales permanecen donde están. Ask FLOW incluye tus tareas solo cuando activas esa opción.
Start focus|Iniciar foco|Iniciar concentración
Focus sounds|Sons do foco|Sonidos de concentración
Mute focus sounds|Silenciar sons do foco|Silenciar sonidos de concentración
Chime when time ends|Avisar quando o tempo terminar|Avisar al terminar el tiempo
During focus|Durante o foco|Durante la concentración
Silence|Silêncio|Silencio
Soft ticking|Tique-taque suave|Tictac suave
Brown noise|Ruído marrom|Ruido marrón
Pink noise|Ruído rosa|Ruido rosa
Soft rain|Chuva suave|Lluvia suave
Volume|Volume|Volumen
Try chime|Ouvir aviso|Escuchar aviso
Choose what feels comfortable. Background sound stops when you pause or close focus.|Escolha o que for confortável. O som de fundo para ao pausar ou fechar o foco.|Elige lo que te resulte cómodo. El sonido se detiene al pausar o cerrar la concentración.
Sound could not play. Try selecting it again.|Não foi possível reproduzir o som. Tente selecioná-lo novamente.|No se pudo reproducir el sonido. Intenta seleccionarlo de nuevo.
Focus could not open. Please try again.|Não foi possível abrir o Foco. Tente novamente.|No se pudo abrir Concentración. Inténtalo de nuevo.
Kept in Memory|Guardado na Memória|Guardado en Memoria
Memory · %@ safely remembered|Memória · %@ guardadas com segurança|Memoria · %@ guardadas con seguridad
Kept in Later|Guardado em Depois|Guardado en Después
Mark for today|Marcar para agora|Marcar para ahora
Remove from today|Retirar de Agora|Quitar de Ahora
CHOSEN FOR TODAY|ESCOLHIDOS PARA AGORA|ELEGIDOS PARA AHORA
Focus duration|Tempo de foco|Duración de concentración
Default: %@ minutes|Padrão: %@ minutos|Predeterminado: %@ minutos
Focus starts automatically with the task estimate, or this duration when there is no estimate. Change it anytime in the mini player.|O foco começa automaticamente com a estimativa da tarefa ou, sem estimativa, com esta duração. Ajuste quando quiser no mini player.|La concentración empieza automáticamente con la estimación de la tarea o, sin estimación, con esta duración. Ajústala en el mini player.
Choose your time, then press play.|Escolha o tempo e aperte iniciar.|Elige el tiempo y pulsa iniciar.
Tasks, memories and ideas, together.|Tarefas, projetos e hábitos.|Tareas, proyectos y hábitos.
Search tasks and memories|Buscar tarefas|Buscar tareas
Search tasks|Buscar tarefas|Buscar tareas
Tasks, projects and habits.|Tarefas, projetos e hábitos.|Tareas, proyectos y hábitos.
Include my tasks|Incluir minhas tarefas|Incluir mis tareas
Only this conversation goes to your configured AI.|Somente esta conversa é enviada à sua IA configurada.|Solo esta conversación se envía a tu IA configurada.
This conversation and up to 100 recent tasks go to your configured AI. You choose what to keep.|Esta conversa e até 100 tarefas recentes são enviadas à sua IA configurada. Você escolhe o que salvar.|Esta conversación y hasta 100 tareas recientes se envían a tu IA configurada. Tú eliges qué guardar.
YOUR DATA, YOUR CONTROL|SEUS DADOS, SEU CONTROLE|TUS DATOS, TU CONTROL
Delete all tasks…|Excluir todas as tarefas…|Eliminar todas las tareas…
Delete all tasks|Excluir todas as tarefas|Eliminar todas las tareas
Delete all tasks and projects?|Excluir todas as tarefas e projetos?|¿Eliminar todas las tareas y proyectos?
This clears tasks, habits and projects. Your achievement history stays saved.|Isso remove tarefas, hábitos e projetos. Seu histórico de conquistas permanece salvo.|Esto elimina tareas, hábitos y proyectos. Tu historial de logros permanece guardado.
Task title|Título da tarefa|Título de la tarea
Habit or ritual|Hábito ou ritual|Hábito o ritual
Capture task|Capturar tarefa|Capturar tarea
Task to capture|Tarefa para capturar|Tarea para capturar
Delete this task?|Excluir esta tarefa?|¿Eliminar esta tarea?
AI is unavailable. You can still save tasks.|A IA está indisponível. Você ainda pode salvar tarefas.|La IA no está disponible. Puedes guardar tareas.
AI is unavailable. Your tasks are safe.|A IA está indisponível. Suas tarefas estão seguras.|La IA no está disponible. Tus tareas están seguras.
Find a small, possible first step for your task.|Encontre um primeiro passo pequeno e possível para sua tarefa.|Encuentra un primer paso pequeño y posible para tu tarea.
Capture any unfinished tasks.|Capture as tarefas pendentes.|Captura las tareas pendientes.
Tasks and focus sessions are saved locally on this Mac, with Lamp’s local backups.|Tarefas e sessões de foco são salvas neste Mac, com backups locais do Lamp.|Las tareas y sesiones de concentración se guardan en este Mac, con copias locales de Lamp.
Choose your language. AI replies follow your choice; task titles stay as you wrote them.|Escolha seu idioma. A IA segue sua escolha; os títulos das tarefas continuam como você escreveu.|Elige tu idioma. La IA sigue tu elección; los títulos de tareas quedan como los escribiste.
Capture a task without organising it first.|Capture uma tarefa sem precisar organizar antes.|Captura una tarea sin organizarla primero.
Review your tasks without judging the list.|Revise suas tarefas sem julgar a lista.|Revisa tus tareas sin juzgar la lista.
Keep everything here. Choose what belongs to today, or take a moment to focus.|Guarde tudo aqui. Escolha o que fazer agora ou tire um momento para focar.|Guarda todo aquí. Elige qué hacer ahora o dedica un momento a concentrarte.
Later|Depois|Después
Move to project|Mover para projeto|Mover a proyecto
A little space for what comes next.|Um espaço para o que vem depois.|Un espacio para lo que viene después.
Capture new tasks in Capture. Drag tasks onto a project to organise them.|Crie tarefas em Capturar. Arraste tarefas para um projeto para organizá-las.|Crea tareas en Capturar. Arrastra tareas a un proyecto para organizarlas.
Drop tasks here|Solte tarefas aqui|Suelta tareas aquí
How would you like to capture?|Como você quer capturar?|¿Cómo quieres capturar?
AI isn’t ready. Suggestions need AI; you can still save a thought.|A IA ainda não está pronta. As sugestões precisam dela; você ainda pode salvar um pensamento.|La IA aún no está lista. Las sugerencias la necesitan; aún puedes guardar un pensamiento.
AI isn’t ready. Retry extracted text later, or add the file again. Temporary files are removed after processing.|A IA ainda não está pronta. Tente o texto extraído mais tarde ou adicione o arquivo novamente. Arquivos temporários são removidos após o processamento.|La IA aún no está lista. Reintenta con el texto extraído más tarde o añade el archivo de nuevo. Los archivos temporales se eliminan después del procesamiento.
Add the file again to retry|Adicione o arquivo novamente para tentar outra vez|Añade el archivo de nuevo para reintentar
Ready to retry from extracted text|Pronto para tentar novamente com o texto extraído|Listo para reintentar con el texto extraído
Cancelled|Cancelado|Cancelado
Type|Digitar|Escribir
Speak|Falar|Hablar
Files|Arquivos|Archivos
Drop a file to find your next tasks.|Solte um arquivo para encontrar suas próximas tarefas.|Suelta un archivo para encontrar tus próximas tareas.
AI reads the content and suggests tasks for you to review. FLOW does not keep the file after processing. Your original stays where it is.|A IA lê o conteúdo e sugere tarefas para você revisar. O FLOW não guarda o arquivo após o processamento. Seu original continua onde está.|La IA lee el contenido y sugiere tareas para que las revises. FLOW no guarda el archivo después del procesamiento. Tu original permanece donde está.
Only extracted text and suggestions remain. Selected pictures and extracted text go to your configured AI.|Ficam apenas o texto extraído e as sugestões. Imagens selecionadas e texto extraído vão para sua IA configurada.|Solo quedan el texto extraído y las sugerencias. Las imágenes seleccionadas y el texto extraído van a tu IA configurada.
Speak freely. FLOW will suggest tasks from what you say.|Fale à vontade. O FLOW vai sugerir tarefas a partir do que você disser.|Habla libremente. FLOW sugerirá tareas a partir de lo que digas.
The spoken language is detected automatically. The recording is removed after processing.|O idioma da fala é detectado automaticamente. A gravação é removida após o processamento.|El idioma se detecta automáticamente. La grabación se elimina después del procesamiento.
Recording…|Gravando…|Grabando…
Stop and find tasks|Parar e encontrar tarefas|Parar y encontrar tareas
Start recording|Começar gravação|Empezar a grabar
Microphone access wasn’t allowed. You can type or choose an audio file instead.|O acesso ao microfone não foi permitido. Você pode digitar ou escolher um arquivo de áudio.|No se permitió el acceso al micrófono. Puedes escribir o elegir un archivo de audio.
Audio: offline speech, up to 20 minutes per file. Video: speech plus up to eight sampled frames. Files are removed after processing; add them again if needed.|Áudio: transcrição offline de até 20 minutos por arquivo. Vídeo: fala e até oito imagens. Os arquivos são removidos após o processamento; adicione novamente se precisar.|Audio: transcripción sin conexión de hasta 20 minutos por archivo. Vídeo: habla y hasta ocho imágenes. Los archivos se eliminan después del procesamiento; añádelos de nuevo si hace falta.
Plans|Planos|Planes
Tasks|Tarefas|Tareas
Habits|Hábitos|Hábitos
Projects|Projetos|Proyectos
Task|Tarefa|Tarea
Habit|Hábito|Hábito
Project|Projeto|Proyecto
One place for tasks, habits, and projects. Your pace, always.|Um lugar para tarefas, hábitos e projetos. Sempre no seu ritmo.|Un lugar para tareas, hábitos y proyectos. Siempre a tu ritmo.
Show plans|Mostrar planos|Mostrar planes
Status|Status|Estado
Active|Ativos|Activos
Completed|Concluídos|Completados
All|Todos|Todos
Search your plans|Buscar nos seus planos|Buscar en tus planes
Edit project|Editar projeto|Editar proyecto
All projects|Todos os projetos|Todos los proyectos
Room for your next small plan|Espaço para seu próximo pequeno plano|Espacio para tu próximo pequeño plan
Add something new, or change the filters to find an existing plan.|Adicione algo novo ou ajuste os filtros para encontrar um plano existente.|Añade algo nuevo o ajusta los filtros para encontrar un plan existente.
New project|Novo projeto|Nuevo proyecto
New habit|Novo hábito|Nuevo hábito
New task|Nova tarefa|Nueva tarea
Delete this plan?|Excluir este plano?|¿Eliminar este plan?
The project is removed. Its tasks and habits stay in your plans.|O projeto será removido. Suas tarefas e hábitos continuarão nos seus planos.|El proyecto se eliminará. Sus tareas y hábitos seguirán en tus planes.
This removes the plan and its saved habit history.|Isso remove o plano e seu histórico de hábito salvo.|Esto elimina el plan y su historial de hábito guardado.
Complete this occurrence|Concluir esta ocorrência|Completar esta ocasión
Reopen task|Reabrir tarefa|Reabrir tarea
Complete task|Concluir tarefa|Completar tarea
Start focus|Iniciar foco|Iniciar concentración
Resume habit|Retomar hábito|Retomar hábito
Pause habit|Pausar hábito|Pausar hábito
Reopen|Reabrir|Reabrir
Mark completed|Marcar como concluído|Marcar como completado
Plan actions|Ações do plano|Acciones del plan
%@ of %@ completed|%@ de %@ concluídos|%@ de %@ completados
View tasks|Ver tarefas|Ver tareas
View habits|Ver hábitos|Ver hábitos
Project progress|Progresso do projeto|Progreso del proyecto
Paused|Pausado|Pausado
Weekdays|Dias úteis|Días laborables
Weekly|Semanalmente|Semanalmente
Every two days|A cada dois dias|Cada dos días
Daily|Diariamente|Diariamente
%@ completions|%@ conclusões|%@ veces completado
A new small plan|Um novo pequeno plano|Un nuevo pequeño plan
Edit your plan|Editar seu plano|Editar tu plan
Type|Tipo|Tipo
Next small step|Próximo pequeno passo|Próximo pequeño paso
No project|Sem projeto|Sin proyecto
Repeat|Repetir|Repetir
Completing a habit schedules its next occurrence. Missed days never add extra tasks.|Concluir um hábito agenda a próxima ocorrência. Dias perdidos nunca acumulam tarefas extras.|Completar un hábito programa su próxima ocasión. Los días perdidos nunca acumulan tareas extra.
Choose next occurrence|Escolher próxima ocorrência|Elegir próxima ocasión
Set a date|Definir uma data|Elegir una fecha
Next occurrence|Próxima ocorrência|Próxima ocasión
Date|Data|Fecha
Begin with five minutes|Comece com cinco minutos|Empieza con cinco minutos
A little habit, gently kept. It will return when it’s time.|Um pequeno hábito, com carinho. Ele voltará na hora certa.|Un pequeño hábito, con cariño. Volverá cuando sea el momento.
Capture|Capturar|Capturar
Focus|Foco|Concentración
Memory|Memória|Memoria
You|Você|Tú
Achievements|Conquistas|Logros
Restore example content|Restaurar conteúdo de exemplo|Restaurar contenido de ejemplo
Example content restored.|Conteúdo de exemplo restaurado.|Contenido de ejemplo restaurado.
Your companion|Seu companheiro|Tu compañero
A moment worth keeping.|Um momento para guardar.|Un momento para guardar.
You made room for your habit.|Você abriu espaço para seu hábito.|Hiciste espacio para tu hábito.
Finish project|Finalizar projeto|Terminar proyecto
Reopen project|Reabrir projeto|Reabrir proyecto
Look how far you’ve come.|Veja o quanto você já caminhou.|Mira cuánto has avanzado.
Your past progress is still yours.|Tudo o que você já conquistou continua sendo seu.|Tu progreso sigue siendo tuyo.
Small steps. Real progress.|Pequenos passos. Progresso de verdade.|Pequeños pasos. Progreso real.
That was a big one. You did it!|Foi um grande passo. Você conseguiu!|Fue un gran paso. ¡Lo lograste!
Look at everything you made happen!|Olha tudo o que você fez acontecer!|¡Mira todo lo que hiciste posible!
One more thing off your mind.|Uma coisa a menos para carregar.|Una cosa menos en tu mente.
Every journey starts somewhere.|Toda jornada tem um começo.|Todo camino tiene un comienzo.
Your victories will live here.|Suas conquistas vão morar aqui.|Tus logros vivirán aquí.
Your victories|Suas conquistas|Tus logros
Moments worth remembering|Momentos para lembrar|Momentos para recordar
The moments that matter to you.|Os momentos que importam para você.|Los momentos que te importan.
Perspective|Período|Período
This week|Esta semana|Esta semana
This month|Este mês|Este mes
All time|Todo o período|Todo el período
Tasks completed|Tarefas concluídas|Tareas completadas
Projects finished|Projetos finalizados|Proyectos terminados
Habits practiced|Hábitos praticados|Hábitos practicados
Personal milestones|Marcos pessoais|Hitos personales
Milestone|Marco pessoal|Hito personal
Activity|Atividade|Actividad
Search victories|Buscar conquistas|Buscar logros
Nothing in this view yet|Ainda não há registros neste período|Todavía no hay registros aquí
Everything you’ve accomplished still counts.|Tudo o que você conquistou continua valendo.|Todo lo que has logrado sigue contando.
Yesterday|Ontem|Ayer
Earlier|Anteriores|Anteriores
Date not recorded|Data não registrada|Fecha no registrada
Older completed items without a saved date appear in All time. Their completion dates are not guessed.|Conclusões antigas sem data aparecem em Todo o período. Nenhuma data é inventada.|Los elementos antiguos sin fecha aparecen en Todo el período. No se inventan fechas.
Demonstration tasks are excluded from your victories.|Tarefas de demonstração não contam como conquistas.|Las tareas de demostración no cuentan como logros.
Edit personal note|Editar anotação pessoal|Editar nota personal
Mark as special|Marcar como especial|Marcar como especial
Remove from special moments|Retirar dos momentos especiais|Quitar de momentos especiales
Companion keepsakes|Lembranças do personagem|Recuerdos del personaje
Small reminders, never points. Choose an unlocked keepsake to display beside your companion.|Pequenas lembranças, sem pontos. Escolha uma lembrança desbloqueada para mostrar junto ao personagem.|Pequeños recuerdos, sin puntos. Elige uno desbloqueado para mostrar junto al personaje.
First step|Primeiro passo|Primer paso
One genuine victory|Uma conquista real|Un logro real
Growing gently|Crescendo com calma|Creciendo con calma
Five habit occurrences|Cinco práticas de hábitos|Cinco prácticas de hábitos
A chapter complete|Um capítulo concluído|Un capítulo terminado
One finished project|Um projeto finalizado|Un proyecto terminado
Worth remembering|Vale lembrar|Vale la pena recordar
One personal milestone|Um marco pessoal|Un hito personal
Celebration preferences|Preferências de celebração|Preferencias de celebración
Reduce celebration animation|Reduzir animações de celebração|Reducir animaciones de celebración
Celebration sounds|Sons de celebração|Sonidos de celebración
Mute praise and celebration messages|Silenciar elogios e mensagens de celebração|Silenciar elogios y celebraciones
Celebrations are brief and dismissible. Your Mac’s reduced-motion preference is always respected.|As celebrações são breves e podem ser dispensadas. A preferência do Mac por movimento reduzido é sempre respeitada.|Las celebraciones son breves y se pueden cerrar. Siempre se respeta el movimiento reducido del Mac.
Dismiss celebration|Dispensar celebração|Cerrar celebración
What would you like to remember?|O que você gostaria de lembrar?|¿Qué te gustaría recordar?
Personal note (optional)|Anotação pessoal (opcional)|Nota personal (opcional)
Connections|Conexões|Conexiones
App language|Idioma do app|Idioma de la app
Language|Idioma|Idioma
Connect checks access and reads this source. Notes uses AI to read visible notes. Other sources stay on this Mac until you choose Find tasks & links. Nothing runs in the background.|Conectar verifica o acesso e lê esta fonte. Notas usa IA para ler notas visíveis. As outras fontes ficam neste Mac até você escolher Encontrar tarefas e vínculos. Nada roda em segundo plano.|Conectar comprueba el acceso y lee esta fuente. Notas usa IA para leer notas visibles. Las otras fuentes quedan en este Mac hasta que elijas Encontrar tareas y vínculos. Nada se ejecuta en segundo plano.
Connecting…|Conectando…|Conectando…
Connect|Conectar|Conectar
Check again|Verificar novamente|Comprobar de nuevo
Connected. No matches for this search.|Conectado. Nenhum resultado para esta busca.|Conectado. Sin resultados para esta búsqueda.
Connected. No items in this range.|Conectado. Nenhum item neste intervalo.|Conectado. Sin elementos en este intervalo.
Connected · %@ items read|Conectado · %@ itens lidos|Conectado · %@ elementos leídos
Connection needs attention|A conexão precisa de atenção|La conexión necesita atención
Your character theme brings its colours and personality. Change it anytime in You → Appearance.|Seu tema de personagem traz suas cores e personalidade. Mude quando quiser em Você → Aparência.|Tu tema de personaje aporta sus colores y personalidad. Cámbialo en Tú → Apariencia.
Drop something above. FLOW will look for tasks, with evidence for every suggestion.|Solte algo acima. O FLOW vai procurar tarefas com evidências para cada sugestão.|Suelta algo arriba. FLOW buscará tareas con pruebas para cada sugerencia.
Capture finds task suggestions automatically when you drop files, share content, or submit text. Extracted text and selected pictures go to your configured AI. You choose which tasks to keep. Ask FLOW uses AI when you ask.|A Captura encontra sugestões ao soltar arquivos, compartilhar conteúdo ou enviar texto. Texto extraído e imagens selecionadas vão para sua IA. Você escolhe o que guardar. Pergunte ao FLOW usa IA quando você pede.|Captura encuentra sugerencias al soltar archivos, compartir contenido o enviar texto. El texto extraído y las imágenes seleccionadas van a tu IA. Tú eliges qué guardar. Pregunta a FLOW usa IA cuando lo pides.
Read your sources to find tasks and connect the dots.|Leia suas fontes para encontrar tarefas e conectar informações.|Lee tus fuentes para encontrar tareas y conectar información.
Connection settings|Configurações de conexões|Ajustes de conexiones
Open Capture to review connected sources.|Abra Capturar para revisar as fontes conectadas.|Abre Capturar para revisar las fuentes conectadas.
Reading sources…|Lendo fontes…|Leyendo fuentes…
Finding tasks and related intentions…|Encontrando tarefas e intenções relacionadas…|Buscando tareas e intenciones relacionadas…
Mail: up to 30 recent matches. Calendar: the next seven days. Notes: up to 10 visible recent notes.|Mail: até 30 resultados recentes. Calendário: próximos sete dias. Notas: até 10 notas recentes visíveis.|Mail: hasta 30 resultados recientes. Calendario: próximos siete días. Notas: hasta 10 notas recientes visibles.
Read Notes with AI|Ler Notas com IA|Leer Notas con IA
Read sources|Ler fontes|Leer fuentes
Find tasks & links|Encontrar tarefas e vínculos|Encontrar tareas y vínculos
Finding tasks sends selected source text and up to 100 active FLOW tasks to your AI. You review new tasks and suggested links. Notes reading uses AI to look at Notes.|Encontrar tarefas envia o texto selecionado e até 100 tarefas ativas do FLOW para sua IA. Você revisa novas tarefas e vínculos sugeridos. A leitura de Notas usa IA para olhar o app Notas.|Encontrar tareas envía el texto seleccionado y hasta 100 tareas activas de FLOW a tu IA. Tú revisas las nuevas tareas y los vínculos sugeridos. La lectura de Notas usa IA para mirar la app Notas.
This source is off. Read sources to enable it, or choose sources in Settings.|Esta fonte está desativada. Leia fontes para ativar ou escolha nas Configurações.|Esta fuente está desactivada. Lee fuentes para activarla o elige en Ajustes.
Read a source to see items here.|Leia uma fonte para ver os itens aqui.|Lee una fuente para ver sus elementos aquí.
Source evidence|Evidências da fonte|Evidencia de la fuente
Suggested related task|Tarefa relacionada sugerida|Tarea relacionada sugerida
Confirm link|Confirmar vínculo|Confirmar vínculo
Link to existing task|Vincular a uma tarefa existente|Vincular a una tarea existente
Suggestions are in your capture pocket below.|As sugestões estão no seu bolso de capturas abaixo.|Las sugerencias están en tu bolsillo de capturas debajo.
Choose sources FLOW may read when you ask in Capture. Nothing runs in the background. Turning a source off stops future scans; saved captures and links stay.|Escolha as fontes que o FLOW pode ler quando você pedir em Capturar. Nada roda em segundo plano. Desativar uma fonte interrompe novas análises; capturas e vínculos salvos permanecem.|Elige las fuentes que FLOW puede leer cuando lo pidas en Capturar. Nada se ejecuta en segundo plano. Desactivar una fuente detiene nuevos análisis; las capturas y vínculos guardados permanecen.
Open connections in Capture|Abrir conexões em Capturar|Abrir conexiones en Capturar
Related sources|Fontes relacionadas|Fuentes relacionadas
Remove link|Remover vínculo|Quitar vínculo
Notes could not be read. Open Notes and try again.|Não foi possível ler as notas. Abra Notas e tente novamente.|No se pudieron leer las notas. Abre Notas e inténtalo de nuevo.
Connections live in Capture. Read email, calendar, reminders or notes to find tasks and related context.|As conexões ficam em Capturar. Leia e-mails, calendário, lembretes ou notas para encontrar tarefas e contexto relacionado.|Las conexiones están en Capturar. Lee correos, calendario, recordatorios o notas para encontrar tareas y contexto relacionado.
FLOW reads sources only when you ask in Capture. AI suggests tasks and links for you to review; it does not write emails or change your accounts.|O FLOW lê fontes só quando você pede em Capturar. A IA sugere tarefas e vínculos para sua revisão; não escreve e-mails nem altera suas contas.|FLOW lee fuentes solo cuando lo pides en Capturar. La IA sugiere tareas y vínculos para que los revises; no escribe correos ni cambia tus cuentas.
Character theme|Tema do personagem|Tema del personaje
Your brain, uncomplicated.|Sua mente, sem complicação.|Tu mente, sin complicaciones.
Appearance|Aparência|Apariencia
Appearance & assistant|Aparência e assistente|Apariencia y asistente
Colour mode|Modo de cor|Modo de color
System|Sistema|Sistema
Light|Claro|Claro
Dark|Escuro|Oscuro
Your assistant|Seu assistente|Tu asistente
Companion|Companheiro|Compañero
Animal companion|Companheiro animal|Compañero animal
Companion palette|Paleta do companheiro|Paleta del compañero
Turtle|Tartaruga|Tortuga
Rabbit|Coelho|Conejo
Fox|Raposa|Zorro
Cat|Gato|Gato
Sage & fern|Sálvia e samambaia|Salvia y helecho
Rose & cream|Rosa e creme|Rosa y crema
Amber & rust|Âmbar e ferrugem|Ámbar y óxido
Charcoal & gold|Carvão e ouro|Carbón y oro
Your animal brings its own colours to backgrounds, glass, buttons, and highlights.|Seu companheiro traz suas cores para fundos, vidro, botões e destaques.|Tu compañero aporta sus colores a fondos, cristal, botones y detalles.
Changes the character and tone. All assistants use the same configured AI.|Muda o personagem e o tom. Todos usam a mesma IA configurada.|Cambia el personaje y el tono. Todos usan la misma IA configurada.
Ask FLOW|Pergunte ao FLOW|Pregunta a FLOW
Break into little missions · AI|Dividir em pequenas missões · IA|Dividir en pequeñas misiones · IA
Save as task|Salvar como tarefa|Guardar como tarea
Save as thought|Salvar como pensamento|Guardar como pensamiento
Send message|Enviar mensagem|Enviar mensaje
Stop response|Parar resposta|Detener respuesta
Processed on this Mac|Processado neste Mac|Procesado en este Mac
Processed by your AI service|Processado pelo seu serviço de IA|Procesado por tu servicio de IA
This conversation and up to 100 recent saved thoughts go to your configured AI. You choose what to keep.|Esta conversa e até 100 tarefas recentes são enviadas à sua IA configurada. Você escolhe o que salvar.|Esta conversación y hasta 100 tareas recientes se envían a tu IA configurada. Tú eliges qué guardar.
This conversation goes to your configured AI. Saved thoughts stay on this Mac.|Esta conversa é enviada à sua IA configurada. Suas memórias ficam neste Mac.|Esta conversación se envía a tu IA configurada. Tus recuerdos quedan en este Mac.
Saved source: %@|Memória consultada: %@|Recuerdo consultado: %@
Keep this step|Guardar este passo|Guardar este paso
Kept|Guardado|Guardado
FLOW couldn’t get an answer.|O FLOW não conseguiu responder.|FLOW no pudo responder.
Take a breath|Respire um pouco|Respira un momento
Help me reset|Me ajude a recomeçar|Ayúdame a empezar de nuevo
Expand sidebar|Expandir menu lateral|Expandir barra lateral
Collapse sidebar|Recolher menu lateral|Contraer barra lateral
Save|Salvar|Guardar
Cancel|Cancelar|Cancelar
Close|Fechar|Cerrar
Done|Concluir|Listo
Continue|Continuar|Continuar
Back|Voltar|Atrás
Skip|Pular|Omitir
Skip for now|Pular por enquanto|Omitir por ahora
Dismiss|Dispensar|Descartar
Delete|Excluir|Eliminar
Delete permanently|Excluir permanentemente|Eliminar permanentemente
Edit|Editar|Editar
Search|Buscar|Buscar
Retry|Tentar novamente|Reintentar
Original|Original|Original
Task|Tarefa|Tarea
Thought|Pensamento|Pensamiento
Idea|Ideia|Idea
Minutes|Minutos|Minutos
Kind|Tipo|Tipo
Deadline|Prazo|Fecha límite
Due|Prazo|Vencimiento
Add a deadline|Adicionar prazo|Añadir fecha límite
Remove deadline|Remover prazo|Quitar fecha límite
Has a deadline|Tem prazo|Tiene fecha límite
First tiny step|Primeiro pequeno passo|Primer pequeño paso
First tiny physical step|Primeiro pequeno passo físico|Primer pequeño paso físico
Smallest next step|Menor próximo passo|Siguiente paso más pequeño
Make it smaller|Simplificar|Hazlo más pequeño
Make this smaller|Simplifique isso|Haz esto más pequeño
Choose this|Escolher esta|Elegir esta
 Complete|Concluir|Completar
 Mark complete|Marcar como concluída|Marcar como completada
This task is complete|Esta tarefa está concluída|Esta tarea está completada
Example|Exemplo|Ejemplo
TODAY|HOJE|HOY
A small step.\nA lighter day.|Um pequeno passo.\nUm dia mais leve.|Un pequeño paso.\nUn día más ligero.
Just your next little thing, at your own pace.|Só o próximo pequeno passo, no seu ritmo.|Solo tu próximo pequeño paso, a tu ritmo.
How much room today?|Quanto tempo cabe hoje?|¿Cuánto tiempo tienes hoy?
How much time do you have available now?|Quanto tempo você tem disponível agora?|¿Cuánto tiempo tienes disponible ahora?
Now|Agora|Ahora
Choose another task|Escolher outra tarefa|Elegir otra tarea
Choose for now|Escolher para agora|Elegir para ahora
Your choice comes first, even if it takes longer than your available time.|Sua escolha vem primeiro, mesmo que precise de mais tempo do que você tem disponível.|Tu elección tiene prioridad, aunque necesite más tiempo del que tienes disponible.
No tasks found|Nenhuma tarefa encontrada|No se encontraron tareas
Capture something new, or try another search.|Capture algo novo ou tente outra busca.|Captura algo nuevo o prueba otra búsqueda.
NOW|AGORA|AHORA
Kept for Later|Guardado para Depois|Guardado para Después
Later · %@ safely remembered|Depois · %@ guardadas com segurança|Después · %@ guardadas con seguridad
YOUR NEXT LITTLE QUEST|SUA PRÓXIMA PEQUENA MISSÃO|TU PRÓXIMA PEQUEÑA MISIÓN
Let’s go · 5 minutes|Vamos lá · 5 minutos|Vamos · 5 minutos
A little room to breathe|Um espaço para respirar|Un espacio para respirar
Capture something to remember, or simply enjoy the space.|Capture algo para lembrar ou simplesmente aproveite o espaço.|Captura algo para recordar o simplemente disfruta del espacio.
NEXT · WHEN YOU’RE READY|DEPOIS · QUANDO ESTIVER PRONTO|DESPUÉS · CUANDO ESTÉS LISTO
TIME HORIZON|HORIZONTE DE TEMPO|HORIZONTE DE TIEMPO
A window, not a whole day.|Um intervalo, não um dia inteiro.|Un intervalo, no un día entero.
Manual time window · See your calendar in Connections.|Intervalo manual · Veja seu calendário em Conexões.|Intervalo manual · Consulta tu calendario en Conexiones.
Available time|Tempo disponível|Tiempo disponible
Begin wherever you are|Comece de onde estiver|Empieza donde estés
Little quest. Real victory.|Pequena missão. Vitória de verdade.|Pequeña misión. Victoria real.
Look at you, making room for life.|Olha você, abrindo espaço para a vida.|Mírate, haciendo espacio para la vida.
Onward, at my pace|Em frente, no meu ritmo|Adelante, a mi ritmo
The keepsake shelf|A prateleira de lembranças|El estante de recuerdos
Thoughts, promises, and little things worth holding onto.|Pensamentos, promessas e pequenas coisas que vale guardar.|Pensamientos, promesas y pequeñas cosas que vale la pena guardar.
Find a thought, a person, a promise…|Encontre um pensamento, uma pessoa, uma promessa…|Encuentra un pensamiento, una persona, una promesa…
Search memories|Buscar memórias|Buscar recuerdos
Nothing to carry yet|Nada para guardar ainda|Nada que guardar todavía
Anything you capture will be here.|Tudo que você capturar estará aqui.|Todo lo que captures estará aquí.
Ask about my memories|Perguntar sobre minhas memórias|Preguntar sobre mis recuerdos
Find your rhythm|Encontre seu ritmo|Encuentra tu ritmo
Your pace. Your rules. Fresh starts are always welcome.|Seu ritmo. Suas regras. Recomeços são sempre bem-vindos.|Tu ritmo. Tus reglas. Siempre puedes empezar de nuevo.
FLEXIBLE RITUALS|RITUAIS FLEXÍVEIS|RITUALES FLEXIBLES
A gentle routine|Uma rotina leve|Una rutina tranquila
Morning launch|Começo da manhã|Comienzo de la mañana
Leaving home|Saindo de casa|Salir de casa
Workday reset|Pausa no trabalho|Pausa en el trabajo
Evening shutdown|Encerrando o dia|Cerrar el día
Weekly reorientation|Reorganização semanal|Reorientación semanal
Next small step|Próximo pequeno passo|Siguiente pequeño paso
Start again anytime|Recomece quando quiser|Vuelve a empezar cuando quieras
YOUR MEMORY, YOUR CONTROL|SUA MEMÓRIA, SEU CONTROLE|TU MEMORIA, TU CONTROL
QUIET BY DEFAULT|TRANQUILO POR PADRÃO|TRANQUILO POR DEFECTO
THREE WAYS FLOW HOLDS YOUR PLACE|TRÊS JEITOS DE GUARDAR SEU LUGAR|TRES FORMAS DE GUARDAR TU LUGAR
Export my thoughts|Exportar meus pensamentos|Exportar mis pensamientos
Remove example content|Remover exemplos|Eliminar ejemplos
Delete all thoughts…|Excluir todos os pensamentos…|Eliminar todos los pensamientos…
Delete all thoughts|Excluir todos os pensamentos|Eliminar todos los pensamientos
Delete all saved thoughts?|Excluir todos os pensamentos salvos?|¿Eliminar todos los pensamientos guardados?
End quiet pause|Encerrar pausa tranquila|Terminar la pausa
A little help getting started|Uma ajudinha para começar|Una ayuda para empezar
Meet FLOW, choose your companion, and find your first small tasks.|Conheça o FLOW, escolha seu companheiro e encontre suas primeiras pequenas tarefas.|Conoce FLOW, elige tu compañero y encuentra tus primeras pequeñas tareas.
Start here|Comece aqui|Empieza aquí
A softer start with FLOW|Um começo mais leve com FLOW|Un comienzo más suave con FLOW
Choose your kind of company|Escolha sua companhia|Elige tu compañía
What’s on your mind?|O que está na sua cabeça?|¿Qué tienes en mente?
Make these first steps yours|Deixe os primeiros passos com a sua cara|Haz tuyos estos primeros pasos
FLOW holds the loose ends so you can begin with one small thing.|O FLOW guarda as pontas soltas para você começar com uma pequena coisa.|FLOW guarda los cabos sueltos para que empieces con una pequeña cosa.
Memory & You|Memória e Você|Memoria y Tú
Drop a file or paste a thought. AI finds possible tasks; you decide what to keep.|Solte um arquivo ou cole um pensamento. A IA encontra possíveis tarefas; você decide o que guardar.|Suelta un archivo o pega un pensamiento. La IA encuentra posibles tareas; tú decides qué guardar.
Choose the time you have. One task takes the spotlight; the rest stay safe.|Escolha o tempo que tem. Uma tarefa ganha destaque; as outras ficam guardadas.|Elige el tiempo que tienes. Una tarea destaca; las demás quedan guardadas.
Start a short timer. Catch distractions and leave a return thread for later.|Comece um cronômetro curto. Capture distrações e deixe uma pista para voltar depois.|Inicia un temporizador corto. Captura distracciones y deja una pista para volver después.
Find saved thoughts, change your companion, or return to this guide.|Encontre pensamentos salvos, mude seu companheiro ou volte a este guia.|Encuentra pensamientos guardados, cambia tu compañero o vuelve a esta guía.
Connect your Mac’s accounts when ready. Every outside change asks first.|Conecte as contas do Mac quando quiser. Toda alteração externa pede confirmação.|Conecta las cuentas del Mac cuando quieras. Cada cambio externo pide confirmación.
Your companion brings its colours and tone. You can change it anytime in You → Appearance & assistant.|Seu companheiro traz suas cores e seu jeito. Mude quando quiser em Você → Aparência e assistente.|Tu compañero aporta sus colores y su estilo. Cámbialo en Tú → Apariencia y asistente.
Tell FLOW a few real things you’d like help starting. Messy sentences are welcome.|Conte ao FLOW algumas coisas reais que gostaria de começar. Pode escrever do seu jeito.|Cuéntale a FLOW algunas cosas reales que quieras empezar. Escribe como te salga.
Things I would like help starting|Coisas que eu gostaria de começar|Cosas que me gustaría empezar
Time for one task|Tempo para uma tarefa|Tiempo para una tarea
Only what you type here and your chosen time go to your configured AI. It suggests up to three editable tasks. Nothing is saved to Today until you keep it.|Só o que você escrever aqui e o tempo escolhido vão para sua IA. Ela sugere até três tarefas editáveis. Nada vai para Hoje até você guardar.|Solo lo que escribas aquí y el tiempo elegido van a tu IA. Sugiere hasta tres tareas editables. Nada va a Hoy hasta que lo guardes.
AI isn’t available yet. You can still write a first task yourself.|A IA ainda não está disponível. Você pode escrever sua primeira tarefa.|La IA aún no está disponible. Puedes escribir tu primera tarea.
Write a task myself|Escrever uma tarefa|Escribir una tarea
Suggest my first tasks|Sugerir minhas primeiras tarefas|Sugerir mis primeras tareas
Finding a few possible beginnings…|Encontrando alguns começos possíveis…|Buscando posibles comienzos…
Keep selected tasks|Guardar tarefas selecionadas|Guardar tareas seleccionadas
Choose what fits, edit anything, and keep only what you want.|Escolha o que cabe, edite qualquer coisa e guarde só o que quiser.|Elige lo que encaje, edita lo que quieras y guarda solo lo que necesites.
Add another task|Adicionar outra tarefa|Añadir otra tarea
Kept in Today and Memory|Guardado em Hoje e Memória|Guardado en Hoy y Memoria
Capture a thought|Capturar um pensamento|Capturar un pensamiento
Your capture pocket|Seu bolso de capturas|Tu bolsillo de capturas
A pocket for the loose ends.|Um bolso para as pontas soltas.|Un bolsillo para los cabos sueltos.
Drop the loose ends here.|Solte as pontas soltas aqui.|Suelta los cabos sueltos aquí.
Files, pictures, recordings, emails, links. Messy is welcome.|Arquivos, fotos, gravações, e-mails, links. Pode mandar tudo junto.|Archivos, fotos, grabaciones, correos, enlaces. El desorden es bienvenido.
Files, photos, recordings, emails, links. I’ll look for the little quests inside.|Arquivos, fotos, gravações, e-mails, links. Vou procurar as pequenas missões.|Archivos, fotos, grabaciones, correos, enlaces. Buscaré las pequeñas misiones.
Choose files|Escolher arquivos|Elegir archivos
Find tasks|Encontrar tarefas|Encontrar tareas
Find my little quests|Encontrar minhas pequenas missões|Encontrar mis pequeñas misiones
Just save as a thought|Só guardar como pensamento|Solo guardar como pensamiento
Keep task|Guardar tarefa|Guardar tarea
Keep this task|Guardar esta tarefa|Guardar esta tarea
Remove source|Remover fonte|Eliminar fuente
Remove this capture source|Remover esta fonte|Eliminar esta fuente
Remove this source and its saved original?|Remover esta fonte e o original salvo?|¿Eliminar esta fuente y su original guardado?
Open the original source|Abrir a fonte original|Abrir la fuente original
Speech language|Idioma da fala|Idioma del habla
Thought to capture|Pensamento para capturar|Pensamiento para capturar
Clear your head|Esvazie a cabeça|Despeja tu mente
A little help from FLOW|Uma ajudinha do FLOW|Una ayuda de FLOW
Help me untangle this|Me ajude a desembolar|Ayúdame a desenredar esto
Include my saved thoughts|Incluir minhas tarefas|Incluir mis tareas
I don’t know where to start|Não sei por onde começar|No sé por dónde empezar
Take your time. Your question is being considered.|Sem pressa. Sua pergunta está sendo considerada.|Sin prisa. Se está considerando tu pregunta.
AI suggestions · You decide what fits.|Sugestões da IA · Você decide o que cabe.|Sugerencias de IA · Tú decides qué encaja.
Turn a tangled thought into a small, possible beginning.|Transforme um pensamento embolado em um começo pequeno e possível.|Convierte un pensamiento enredado en un comienzo pequeño y posible.
Nothing to focus on yet|Nada para focar ainda|Nada en que concentrarse todavía
Capture one intention. A very small one is enough.|Capture uma intenção. Bem pequena já serve.|Captura una intención. Una muy pequeña basta.
Focus time remaining|Tempo de foco restante|Tiempo de concentración restante
Begin gently|Comece com calma|Empieza con calma
Resume gently|Retome com calma|Retoma con calma
Pause|Pausar|Pausar
Another 5 minutes|Mais 5 minutos|Otros 5 minutos
Catch it|Capturar|Capturar
Keep my place|Guardar meu lugar|Guardar mi lugar
When I return, I’ll…|Quando eu voltar, vou…|Cuando vuelva, voy a…
Leave one sentence for your future self.|Deixe uma frase para você no futuro.|Deja una frase para tu yo del futuro.
Return thread · exactly where you left off|Pista de retorno · exatamente onde parou|Pista de regreso · justo donde lo dejaste
The timer is visual only. FLOW won’t interrupt you or other apps.|O cronômetro é apenas visual. O FLOW não interrompe você nem outros apps.|El temporizador es solo visual. FLOW no interrumpe ni a ti ni a otras apps.
We can make this smaller.|Podemos simplificar isso.|Podemos hacerlo más pequeño.
You don’t need to solve everything right now.|Você não precisa resolver tudo agora.|No necesitas resolver todo ahora.
Leave reset|Sair da pausa|Salir de la pausa
Nothing needs choosing. Take a sip of water, or simply pause.|Não precisa escolher nada. Beba um pouco de água ou apenas pause.|No tienes que elegir nada. Bebe un poco de agua o simplemente pausa.
That’s enough for now|Por agora, está bom|Por ahora, basta
Take a breath|Respire um pouco|Respira un momento
Step away if you’d like.|Afaste-se um pouco se quiser.|Aléjate un momento si quieres.
Reminder…|Lembrete…|Recordatorio…
Calendar event…|Evento no calendário…|Evento del calendario…
Email draft…|Rascunho de e-mail…|Borrador de correo…
Working with your accounts…|Acessando suas contas…|Accediendo a tus cuentas…
Your reminders, with room to breathe|Seus lembretes, com espaço para respirar|Tus recordatorios, con espacio para respirar
See the shape of your week|Veja o desenho da sua semana|Mira la forma de tu semana
A little help with your inbox|Uma ajudinha com sua caixa de entrada|Una ayuda con tu bandeja de entrada
Search subject or sender|Buscar assunto ou remetente|Buscar asunto o remitente
Today and the next six days|Hoje e os próximos seis dias|Hoy y los próximos seis días
To · comma-separated addresses|Para · endereços separados por vírgula|Para · direcciones separadas por comas
Starts|Começa|Comienza
Ends|Termina|Termina
Location|Local|Lugar
Preparing your change…|Preparando sua alteração…|Preparando tu cambio…
Complete reminder|Concluir lembrete|Completar recordatorio
Complete in Reminders…|Concluir em Lembretes…|Completar en Recordatorios…
Mark complete in Reminders?|Marcar como concluído em Lembretes?|¿Marcar como completado en Recordatorios?
Connection|Conexão|Conexión
Use the language you feel most comfortable with. AI replies follow your choice. Saved thoughts stay as you wrote them.|Use o idioma que preferir. As respostas da IA seguem sua escolha. Pensamentos salvos continuam como você escreveu.|Usa el idioma que prefieras. Las respuestas de IA siguen tu elección. Los pensamientos guardados quedan como los escribiste.
"""
        var result: [String: [String]] = [:]
        for line in rows.split(separator: "\n") {
            let parts = line.components(separatedBy: "|")
            if parts.count == 3 { result[parts[0]] = Array(parts.dropFirst()) }
        }
        let additional = """
A LITTLE SPACE|UM POUCO DE ESPAÇO|UN POCO DE ESPACIO
 RETURN THREAD|PISTA DE RETORNO|PISTA DE REGRESO
 Focus notes|Anotações de foco|Notas de enfoque
 Where to pick up|Por onde continuar|Por dónde continuar
 Leave a note about your next step. It saves automatically with this task.|Anote seu próximo passo. A anotação é salva automaticamente nesta tarefa.|Anota tu próximo paso. Se guarda automáticamente en esta tarea.
 Something else on your mind?|Pensou em outra coisa?|¿Pensaste en otra cosa?
 Save it in Later and stay with your current task.|Guarde em Depois e continue na tarefa atual.|Guárdalo en Después y continúa con tu tarea actual.
 Write a thought…|Escreva um pensamento…|Escribe un pensamiento…
 Saved in Later|Salvo em Depois|Guardado en Después
 Save thought|Salvar pensamento|Guardar pensamiento
A THOUGHT CAN WAIT HERE|UM PENSAMENTO PODE ESPERAR AQUI|UN PENSAMIENTO PUEDE ESPERAR AQUÍ
A slower pace and gentle reassurance.|Um ritmo mais lento e uma presença acolhedora.|Un ritmo más lento y una presencia amable.
Quick thinking, bright energy, and one clear next hop.|Pensamento rápido, energia e um próximo salto bem claro.|Mente rápida, energía y un próximo salto claro.
Curious thinking and clear, resourceful next steps.|Curiosidade e próximos passos claros e criativos.|Curiosidad y próximos pasos claros y creativos.
Calm company and space to do things your way.|Companhia tranquila e espaço para fazer do seu jeito.|Compañía tranquila y espacio para hacerlo a tu manera.
I’m your turtle. There’s room to take this slowly.|Sou sua tartaruga. Temos espaço para ir com calma.|Soy tu tortuga. Hay espacio para ir con calma.
I’m your rabbit. Bright idea? Let’s find the first little hop.|Sou seu coelho. Teve uma ideia? Vamos encontrar o primeiro pulinho.|Soy tu conejo. ¿Una idea? Busquemos el primer saltito.
I’m your fox. Let’s find a simpler way forward.|Sou sua raposa. Vamos encontrar um caminho mais simples.|Soy tu zorro. Busquemos un camino más sencillo.
I’m your cat. Settle in. We’ll take this your way.|Sou seu gato. Fique à vontade. Vamos no seu ritmo.|Soy tu gato. Ponte cómodo. Iremos a tu ritmo.
Settle in. A gentle beginning is enough.|Fique à vontade. Um começo leve já basta.|Ponte cómodo. Un comienzo tranquilo basta.
One clear little hop. I’ll help keep the rest simple.|Um pulinho de cada vez. Vou ajudar a simplificar o resto.|Un saltito a la vez. Te ayudaré a simplificar el resto.
Just the next step. The rest can wait.|Só o próximo passo. O resto pode esperar.|Solo el próximo paso. Lo demás puede esperar.
Quiet company. Nothing to prove. Just begin.|Companhia tranquila. Nada a provar. Só comece.|Compañía tranquila. Nada que demostrar. Solo empieza.
Catch a distraction, keep your place…|Capture uma distração sem perder seu lugar…|Captura una distracción sin perder tu lugar…
Choose another path|Escolher outro caminho|Elegir otro camino
Delete this thought?|Excluir este pensamento?|¿Eliminar este pensamiento?
End time must be after the start.|O término deve ser depois do início.|El final debe ser después del inicio.
It’s kept. You don’t need to hold it all.|Está guardado. Você não precisa lembrar de tudo.|Está guardado. No necesitas recordarlo todo.
Make this yours.|Deixe com a sua cara.|Hazlo tuyo.
Quiet companion|Companhia tranquila|Compañía tranquila
Show numbers|Mostrar números|Mostrar números
Something smaller: take one sip of water|Algo menor: beba um gole de água|Algo más pequeño: bebe un sorbo de agua
The next step is hiding in there.|O próximo passo está escondido aí.|El próximo paso está escondido ahí.
This removes it from this Mac.|Isso remove o item deste Mac.|Esto elimina el elemento de este Mac.
Your return thread · exactly where you left off|Sua pista de retorno · exatamente onde parou|Tu pista de regreso · justo donde lo dejaste
Safely remembered. Return to what you were doing.|Guardado com segurança. Volte ao que estava fazendo.|Guardado con seguridad. Vuelve a lo que hacías.
Support for everyday decisions. No diagnosis or clinical advice.|Apoio para decisões do dia a dia. Sem diagnóstico ou orientação clínica.|Apoyo para decisiones cotidianas. Sin diagnóstico ni consejo clínico.
AI is unavailable right now. Capture, focus, and reset still work offline.|A IA está indisponível agora. Captura, foco e pausa continuam funcionando offline.|La IA no está disponible. Captura, concentración y pausa siguen funcionando sin conexión.
AI isn’t ready. Sources stay safe here; retry when it’s available.|A IA não está pronta. Suas fontes ficam guardadas aqui; tente de novo depois.|La IA no está lista. Tus fuentes quedan guardadas aquí; reintenta después.
Drop something above. Your assistant will look for tasks, with evidence for every suggestion.|Solte algo acima. Seu assistente vai procurar tarefas com evidências para cada sugestão.|Suelta algo arriba. Tu asistente buscará tareas con pruebas para cada sugerencia.
Drop or send content to find tasks automatically. Extracted text and selected pictures go to your configured AI; originals stay on this Mac. Nothing is sent to other people.|Solte ou envie conteúdo para encontrar tarefas automaticamente. Textos extraídos e imagens selecionadas vão para sua IA; os originais ficam neste Mac. Nada é enviado a outras pessoas.|Suelta o envía contenido para encontrar tareas automáticamente. El texto extraído y las imágenes seleccionadas van a tu IA; los originales quedan en este Mac. Nada se envía a otras personas.
Audio: offline speech, up to 20 minutes per file. Video: speech plus up to eight sampled frames. Unsupported files are kept with an explanation.|Áudio: transcrição offline, até 20 minutos por arquivo. Vídeo: fala e até oito quadros de amostra. Arquivos não compatíveis ficam guardados com uma explicação.|Audio: transcripción sin conexión, hasta 20 minutos por archivo. Vídeo: voz y hasta ocho fotogramas de muestra. Los archivos no compatibles se guardan con una explicación.
In-app suggestions are quiet for 15 minutes. There’s no need to return on a timer.|As sugestões ficam em silêncio por 15 minutos. Não precisa voltar com hora marcada.|Las sugerencias quedan en silencio 15 minutos. No necesitas volver a una hora exacta.
Then return to Today and press Let’s go. Two minutes is a perfectly good start.|Depois volte para Hoje e pressione Vamos lá. Dois minutos já são um ótimo começo.|Después vuelve a Hoy y pulsa Vamos. Dos minutos son un buen comienzo.
This clears active thoughts from this app. Previously exported copies and local backups remain separate.|Isso remove os pensamentos ativos deste app. Cópias exportadas e backups locais permanecem separados.|Esto elimina los pensamientos activos de esta app. Las copias exportadas y las copias locales quedan separadas.
Tasks you already kept remain. Local backups and your original file outside FLOW are separate.|As tarefas guardadas permanecem. Backups locais e o arquivo original fora do FLOW são separados.|Las tareas guardadas permanecen. Las copias locales y tu archivo original fuera de FLOW quedan separados.
Sends only this subject and message to your configured AI. Review the result before opening Mail.|Envia só este assunto e mensagem para sua IA. Revise o resultado antes de abrir o Mail.|Envía solo este asunto y mensaje a tu IA. Revisa el resultado antes de abrir Mail.
Up to 30 recent matches. Drafts open in Mail; FLOW never sends email.|Até 30 resultados recentes. Rascunhos abrem no Mail; o FLOW nunca envia e-mails.|Hasta 30 resultados recientes. Los borradores se abren en Mail; FLOW nunca envía correos.
Thought landing · capture without leaving your current intention.|Pouso de pensamentos · capture sem deixar sua intenção atual.|Aterrizaje de pensamientos · captura sin dejar tu intención actual.
Return thread · leave the exact next move for your future self.|Pista de retorno · deixe o próximo movimento exato para depois.|Pista de regreso · deja el próximo movimiento exacto para después.
Capacity window · see only what can fit the time you choose.|Janela de capacidade · veja só o que cabe no tempo escolhido.|Ventana de capacidad · mira solo lo que cabe en el tiempo elegido.
Thoughts and focus sessions are saved locally on this Mac, with Lamp’s local backups. There’s no account, advertising, or analytics in this version.|Pensamentos e sessões de foco são salvos neste Mac, com backups locais do Lamp. Esta versão não tem conta, publicidade nem análises de uso.|Los pensamientos y sesiones se guardan en este Mac, con copias locales de Lamp. Esta versión no tiene cuenta, publicidad ni análisis de uso.
Capture finds task suggestions automatically when you drop files, share content, or submit text. Extracted text and selected pictures go to your configured AI. You choose which tasks to keep. The assistant uses AI when you ask.|A Captura encontra sugestões automaticamente ao soltar arquivos, compartilhar conteúdo ou enviar texto. Texto extraído e imagens selecionadas vão para sua IA. Você escolhe o que guardar. O assistente usa IA quando você pede.|Captura encuentra sugerencias al soltar archivos, compartir contenido o enviar texto. El texto extraído y las imágenes seleccionadas van a tu IA. Tú eliges qué guardar. El asistente usa IA cuando lo pides.
Exports contain personal information. This prototype doesn’t add its own database encryption or cloud authentication.|Exportações contêm informações pessoais. Este protótipo não adiciona criptografia própria nem autenticação na nuvem.|Las exportaciones contienen datos personales. Este prototipo no añade cifrado propio ni autenticación en la nube.
FLOW reads what you capture and the accounts you choose in Connections. Refresh email, reminders, and calendar when you want. Outside changes ask for confirmation; email drafts open in Mail for you to send.|O FLOW lê suas capturas e as contas escolhidas em Conexões. Atualize e-mails, lembretes e calendário quando quiser. Alterações externas pedem confirmação; rascunhos abrem no Mail para você enviar.|FLOW lee tus capturas y las cuentas elegidas en Conexiones. Actualiza correos, recordatorios y calendario cuando quieras. Los cambios externos piden confirmación; los borradores se abren en Mail para que los envíes.
The quiet clearing|O cantinho tranquilo|El rincón tranquilo
A tiny expedition. Just one thing, for a little while.|Uma pequena expedição. Só uma coisa, por um tempinho.|Una pequeña expedición. Solo una cosa, por un ratito.
A little progress counts.|Um pequeno progresso já conta.|Un pequeño avance cuenta.
Room to pause|Espaço para pausar|Espacio para pausar
Just this moment|Só este momento|Solo este momento
A bridge to your day|Uma ponte para o seu dia|Un puente hacia tu día
Bring the loose ends together. You approve every change.|Junte as pontas soltas. Você aprova cada alteração.|Une los cabos sueltos. Tú apruebas cada cambio.
Email|E-mail|Correo
Reminders|Lembretes|Recordatorios
Calendar|Calendário|Calendario
Prepare email draft|Preparar rascunho de e-mail|Preparar borrador de correo
Prepare reminder|Preparar lembrete|Preparar recordatorio
Prepare event|Preparar evento|Preparar evento
Connect Mail to see recent messages.|Conecte o Mail para ver mensagens recentes.|Conecta Mail para ver mensajes recientes.
No matching messages found.|Nenhuma mensagem encontrada.|No se encontraron mensajes.
Connect Reminders when you’re ready.|Conecte os Lembretes quando quiser.|Conecta Recordatorios cuando quieras.
No open reminders found.|Nenhum lembrete aberto encontrado.|No se encontraron recordatorios pendientes.
Connect Calendar when you’re ready.|Conecte o Calendário quando quiser.|Conecta Calendario cuando quieras.
No events found in this date range.|Nenhum evento encontrado neste período.|No se encontraron eventos en este período.
Kept in FLOW|Guardado no FLOW|Guardado en FLOW
Keep in FLOW|Guardar no FLOW|Guardar en FLOW
Event notes|Notas do evento|Notas del evento
No notes|Sem notas|Sin notas
No subject|Sem assunto|Sin asunto
Reminder|Lembrete|Recordatorio
Calendar event|Evento no calendário|Evento del calendario
Email draft|Rascunho de e-mail|Borrador de correo
Getting started · %@ of 4|Primeiros passos · %@ de 4|Primeros pasos · %@ de 4
%@ minutes|%@ minutos|%@ minutos
%@ little victories, all yours|%@ pequenas vitórias, todas suas|%@ pequeñas victorias, todas tuyas
Connect %@|Conectar %@|Conectar %@ 
Refresh %@|Atualizar %@|Actualizar %@
"""
        for line in additional.split(separator: "\n") {
            let parts = line.components(separatedBy: "|")
            if parts.count == 3 { result[parts[0]] = Array(parts.dropFirst()) }
        }
        let detailRows = """
Prepare %@|Preparar %@|Preparar %@
Open draft in Mail|Abrir rascunho no Mail|Abrir borrador en Mail
Add to Calendar|Adicionar ao Calendário|Añadir a Calendario
Add to Reminders|Adicionar aos Lembretes|Añadir a Recordatorios
Subject|Assunto|Asunto
Title|Título|Título
Message|Mensagem|Mensaje
Notes|Notas|Notas
Writing a suggestion…|Escrevendo uma sugestão…|Escribiendo una sugerencia…
Help me write this|Me ajude a escrever|Ayúdame a escribir
Draft opened in Mail. Nothing was sent.|Rascunho aberto no Mail. Nada foi enviado.|Borrador abierto en Mail. No se envió nada.
Added successfully.|Adicionado com sucesso.|Añadido correctamente.
A draft opens in Mail. You decide whether to send it.|Um rascunho abre no Mail. Você decide se quer enviar.|Se abre un borrador en Mail. Tú decides si enviarlo.
This adds one event to your Mac’s default calendar.|Isso adiciona um evento ao calendário padrão do Mac.|Esto añade un evento al calendario predeterminado del Mac.
This adds one reminder to your Mac’s default reminders list.|Isso adiciona um lembrete à lista padrão do Mac.|Esto añade un recordatorio a la lista predeterminada del Mac.
Prepare outside FLOW|Preparar fora do FLOW|Preparar fuera de FLOW
Chosen by you. Change it whenever you like.|Escolhida por você. Mude quando quiser.|Elegida por ti. Cámbiala cuando quieras.
Fits your time window. Choose differently whenever you like.|Cabe no seu tempo. Escolha outra quando quiser.|Cabe en tu tiempo. Elige otra cuando quieras.
Put your keys, wallet, and phone together.|Junte chaves, carteira e celular.|Junta tus llaves, cartera y teléfono.
Check what you need for the next place.|Confira o que precisa para o próximo lugar.|Revisa qué necesitas para el próximo lugar.
Leave a few minutes of breathing room.|Reserve alguns minutos para respirar.|Deja unos minutos para respirar.
Let your shoulders settle.|Relaxe os ombros.|Relaja los hombros.
Look for the thread you left in Focus.|Procure a pista que deixou em Foco.|Busca la pista que dejaste en Concentración.
Choose just two minutes to begin again.|Escolha só dois minutos para recomeçar.|Elige solo dos minutos para empezar de nuevo.
Capture the loose thought you’re holding.|Capture o pensamento que está guardando na cabeça.|Captura el pensamiento que tienes en la cabeza.
Leave one return thread for tomorrow.|Deixe uma pista de retorno para amanhã.|Deja una pista de regreso para mañana.
Close the day. Enough is enough.|Encerre o dia. Por hoje já basta.|Cierra el día. Por hoy basta.
Look through Memory without judging the list.|Revise suas tarefas sem julgar a lista.|Revisa tus tareas sin juzgar la lista.
Choose one intention that still matters.|Escolha uma intenção que ainda importa.|Elige una intención que aún importe.
Let go of one thing that no longer fits.|Solte uma coisa que já não faz sentido.|Suelta algo que ya no encaje.
Check today’s real commitments in your calendar.|Confira os compromissos reais de hoje no calendário.|Revisa tus compromisos reales de hoy en el calendario.
Choose one small action in Today.|Escolha uma pequena ação em Hoje.|Elige una pequeña acción en Hoy.
Begin with five minutes. The rest can wait.|Comece com cinco minutos. O resto pode esperar.|Empieza con cinco minutos. Lo demás puede esperar.
Reads accounts in Mail when you connect or refresh. Find tasks sends the selected email’s text to your configured AI, with suggestions in Capture.|Lê as contas do Mail ao conectar ou atualizar. Encontrar tarefas envia o texto do e-mail escolhido para sua IA, com sugestões em Capturar.|Lee las cuentas de Mail al conectar o actualizar. Encontrar tareas envía el texto del correo elegido a tu IA, con sugerencias en Capturar.
Reads this week’s events from accounts on your Mac. Find tasks sends only the selected event to AI, with suggestions in Capture.|Lê os eventos desta semana das contas do Mac. Encontrar tarefas envia só o evento escolhido para a IA, com sugestões em Capturar.|Lee los eventos de esta semana de las cuentas del Mac. Encontrar tareas envía solo el evento elegido a la IA, con sugerencias en Capturar.
Reads open reminders from accounts on your Mac. Keeping one in FLOW makes a separate local task; edits don’t sync automatically.|Lê lembretes abertos das contas do Mac. Guardar no FLOW cria uma tarefa local separada; alterações não são sincronizadas automaticamente.|Lee recordatorios pendientes de las cuentas del Mac. Guardar en FLOW crea una tarea local separada; los cambios no se sincronizan automáticamente.
Updated|Atualizado|Actualizado
Sent to Capture for task suggestions.|Enviado para Capturar para sugerir tarefas.|Enviado a Capturar para sugerir tareas.
Marked complete in Reminders.|Marcado como concluído em Lembretes.|Marcado como completado en Recordatorios.
Your thoughts were exported.|Seus pensamentos foram exportados.|Se exportaron tus pensamientos.
The examples are cleared. This space is yours.|Os exemplos foram removidos. Este espaço é seu.|Se eliminaron los ejemplos. Este espacio es tuyo.
Your place is kept. You can return whenever you’re ready.|Seu lugar está guardado. Volte quando quiser.|Tu lugar está guardado. Vuelve cuando quieras.
Your return thread is saved with this task.|Sua pista de retorno está salva nesta tarefa.|Tu pista de regreso está guardada en esta tarea.
Reminder kept in FLOW. Changes in either app stay separate.|Lembrete guardado no FLOW. As alterações em cada app ficam separadas.|Recordatorio guardado en FLOW. Los cambios en cada app quedan separados.
Capture pocket|Bolso de capturas|Bolsillo de capturas
Clear my head|Esvaziar a cabeça|Despejar mi mente
Put the thoughts down. No sorting required.|Coloque os pensamentos aqui. Sem precisar organizar.|Deja aquí tus pensamientos. Sin organizarlos.
Find my next step|Encontrar meu próximo passo|Encontrar mi próximo paso
One manageable action, with room to change it.|Uma ação possível, com espaço para mudar.|Una acción posible, con espacio para cambiarla.
Take a break|Fazer uma pausa|Hacer una pausa
A quiet pause. Everything stays remembered.|Uma pausa tranquila. Tudo continua guardado.|Una pausa tranquila. Todo queda guardado.
Put this down|Guardar isso aqui|Dejar esto aquí
Only 2 minutes|Só 2 minutos|Solo 2 minutos
Leave some space|Deixar um espaço|Dejar un espacio
Read extracted source|Ler texto extraído|Leer texto extraído
A pocket for the loose ends|Um bolso para as pontas soltas|Un bolsillo para los cabos sueltos
Drop the mess. Find the next little quest.|Solte a bagunça. Encontre a próxima pequena missão.|Suelta el desorden. Encuentra la próxima pequeña misión.
Estimated time: %@ minutes|Tempo estimado: %@ minutos|Tiempo estimado: %@ minutos
%@ sources|%@ fontes|%@ fuentes
About %@ min · AI estimate|Cerca de %@ min · Estimativa da IA|Unos %@ min · Estimación de IA
Why this stood out: %@|Por que isso se destacou: %@|Por qué destacó: %@
Later · %@ safely remembered|Depois · %@ guardadas com segurança|Después · %@ guardadas con seguridad
Deadline: %@|Prazo: %@|Fecha límite: %@
You’ve made room for %@ minutes. Keep the last few for a gentle transition.|Você reservou %@ minutos. Guarde os últimos para uma transição tranquila.|Has reservado %@ minutos. Guarda los últimos para una transición tranquila.
Give this a tiny beginning. What’s the first physical action?|Dê um pequeno começo. Qual é a primeira ação física?|Dale un pequeño comienzo. ¿Cuál es la primera acción física?
A small step is enough.|Um pequeno passo já basta.|Un pequeño paso basta.
"""
        let companionRows = """
Moss · the little anchor. Patient, quietly funny, and delighted by small beginnings.|Moss · sua pequena âncora. Paciente, bem-humorado e fã dos pequenos começos.|Moss · tu pequeña ancla. Paciente, divertido y amante de los pequeños comienzos.
Zip · the bright spark. Quick wit, big ideas, one tiny hop at a time.|Zip · uma faísca de ideias. Esperto, cheio de energia, um pulinho de cada vez.|Zip · una chispa de ideas. Ingenioso, lleno de energía, un saltito a la vez.
Fable · the clever explorer. Curious questions and a knack for finding the easier path.|Fable · a exploradora esperta. Perguntas curiosas e um talento para achar o caminho mais fácil.|Fable · la exploradora ingeniosa. Preguntas curiosas y talento para encontrar el camino más fácil.
Briz · the midnight muse. Quiet confidence, dry humour, absolutely no judgement.|Briz · a musa da meia-noite. Confiança tranquila, humor sutil e nenhum julgamento.|Briz · la musa de medianoche. Confianza tranquila, humor sutil y ningún juicio.
I’m Moss. I brought the calm. You just bring yourself.|Sou Moss. Trouxe a calma. Você só precisa chegar.|Soy Moss. Traje la calma. Tú solo necesitas venir.
Zip here! Twelve ideas, one pair of glasses. Let’s pick one little hop.|Zip na área! Doze ideias, um par de óculos. Vamos escolher um pulinho.|¡Zip por aquí! Doce ideas, un par de gafas. Elijamos un saltito.
I’m Fable. A tangled day? Excellent. I know a few shortcuts.|Sou Fable. O dia está embolado? Ótimo. Conheço alguns atalhos.|Soy Fable. ¿Un día enredado? Excelente. Conozco algunos atajos.
Briz here. I’ve cleared a spot beside me. The world can wait a minute.|Briz aqui. Guardei um lugar ao meu lado. O mundo pode esperar um minuto.|Briz aquí. Te guardé un lugar a mi lado. El mundo puede esperar un minuto.
Shell we begin? Slowly is a perfectly lovely speed.|Vamos sair do casco? Devagar é uma velocidade ótima.|¿Salimos del caparazón? Despacio es una velocidad estupenda.
One hop. Just one. I’ll hold the other eleven ideas.|Um pulo. Só um. Eu guardo as outras onze ideias.|Un salto. Solo uno. Yo guardo las otras once ideas.
The clever move? Make the first step wonderfully small.|A jogada esperta? Deixar o primeiro passo bem pequenininho.|¿La jugada inteligente? Hacer el primer paso bien pequeño.
A little focus. Then we can stare thoughtfully out the window.|Um pouco de foco. Depois podemos filosofar olhando pela janela.|Un poco de concentración. Después podemos filosofar mirando por la ventana.
"""
        for line in (detailRows + "\n" + companionRows).split(separator: "\n") {
            let parts = line.components(separatedBy: "|")
            if parts.count == 3 { result[parts[0]] = Array(parts.dropFirst()) }
        }
        result["A small step.\nA lighter day."] = ["Um pequeno passo.\nUm dia mais leve.", "Un pequeño paso.\nUn día más ligero."]
        return result
    }()
}
struct FlowLanguagePicker: View {
    @ObservedObject private var language = FlowLanguageSettings.shared
    var body: some View {
        Picker(FlowL.text("App language"), selection: $language.code) {
            ForEach(FlowLanguageSettings.choices, id: \.0) { choice in
                Text(verbatim: choice.1).tag(choice.0)
            }
        }
    }
}

