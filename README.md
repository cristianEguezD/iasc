# Arquitectura del sistema

![Arquitectura](arquitectura.jpg?raw=true "Arquitectura")

Como primero punto, decidimos utilizar elixir y en particular el modelo de actores debido a que el enunciado del trabajo práctico tenía como objetivos principales lograr que el sistema sea distribuído, tolerar las fallas en el sistema, atender las solicitudes de forma concurrente y otros aspectos que el lenguaje soportaba de forma nativa.
Escogimos utilizar Horde ya que nos provee una gestión transparente de la distribución del sistema.
En cuanto a la arquitectura contamos con:
-   NodeSupervisorObserver: encargado de supervisar al NodeObserver del sistema.
-   NodeObserver: responsable de setear los miembros del sistema cuando un nodo entra o un nodo se cae.
-   NormalQueue: cola que funciona con el esquema tradicional de envío de mensajes.
-   BroadcastQueue: cola especial que funciona con la modalidad Publicar-Suscribir.
-   Consumer: entidad responsable de recibir y procesar pedidos de las queues.
-   QueueAgent: gestiona el estado tanto de las NormalQueue como también de las BroadcastQueue. Existe una por cada queue, esto permite que el estado quede distribuído en todo el sistema y no haya un único punto de falla.
-   Producer: no se encuentra bajo la supervisión de Horde, simplemente son funcionalidades que nos permiten crear distintos tipos de mensajes para que las queues puedan recibirlos.
-   Starter: no se encuentra bajo la supervisión de Horde, nos permite crear las distintas colas y consumidores que necesita el sistema.

# Autores
- Cristian Egüez
- Gerónimo Corti
- Gonzalo Maidán
- Lucas Centurión
