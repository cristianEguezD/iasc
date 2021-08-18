# iasc

### Comunicación

* [Meet](https://meet.google.com/the-undd-esq)
* [Site](https://arquitecturas-concurrentes.github.io/)
* [Discord](https://discord.com/invite/ywcmpBmy)

### Administración

* Parcial: 30/11. Único. 
* TP: fecha **límite**. Semana del 7/12. Se toma la nota del TP como 2da nota.

### Clase

Cada tarea tiene un contexto de ejecucion.

* Concurrencia: sensacion de simultaniedad, no es en el mismo *t* . Se asocia un no determinismo. Multiples contextos de ejecucion asociados a un recurso.
* Paralelismo: ejecución 

Mundo secuencial = mundo super seguro.

Green threads: jacketing (SO)

Ruby MRI: run single thread. Tiene GIL: global interpreter lock. Voluntariamente los threads de ruby ceden el thread nativo (a menos que tengan en lock activo, ahi si corren normal).
  si bien hay un solo thread se pueden intercarlar los "procesos/threads" por lo que la concurrencia puede traer problemas. Se pueden intercarlar si el planificador asi lo dice, por algun cambio de contexto. Puede ser por IO, por un llamado a un método u otras cosas.
  
Ruby sobre jvm: bellísimo.







