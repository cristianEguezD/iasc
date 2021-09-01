# iasc

### Comunicación

* [Meet](https://meet.google.com/the-undd-esq)
* [Site](https://arquitecturas-concurrentes.github.io/)
* [Discord](https://discord.com/invite/ywcmpBmy)

### Administración

* Parcial: 30/11. Único. 
* TP: fecha **límite**. Semana del 7/12. Se toma la nota del TP como 2da nota.

### Clase 1 - 17/08/2021

Cada tarea tiene un contexto de ejecucion.

* Concurrencia: sensacion de simultaniedad, no es en el mismo *t* . Se asocia un no determinismo. Multiples contextos de ejecucion asociados a un recurso.
* Paralelismo: ejecución 

Mundo secuencial = mundo super seguro.

Green threads: jacketing (SO)

Ruby MRI: run single thread. Tiene GIL: global interpreter lock. Voluntariamente los threads de ruby ceden el thread nativo (a menos que tengan en lock activo, ahi si corren normal).
  si bien hay un solo thread se pueden intercarlar los "procesos/threads" por lo que la concurrencia puede traer problemas. Se pueden intercarlar si el planificador asi lo dice, por algun cambio de contexto. Puede ser por IO, por un llamado a un método u otras cosas.
  
Ruby sobre jvm: bellísimo.

[Resumen](https://docs.google.com/document/d/1dgWxbj-XRmJuGuKW-BQVhXbAebWph5gb0OJ_hYBeAM8/edit)

### Clase 2 - 24/08/2021

## Práctca con ruby

* Ambiente: mirar site o mail (deberían haber enviado algo).
* Comunicación: por el canal de discord.

# "INSERTAR" cuadro (armarlo)

Respuestas:

1) No, porque MRI trabaja con GIL lo que hace que haya como máximo un único thread activo.

2) Si, porque aunque solo pueda haber un único thread activo, cuando este se bloquea por IO implica un cambio de contexto, por lo que se puede enviar a ejecutar otro thread.

3) Si, porque con esto obtenemos paralelismo.

4) No, porque se llega a un límite de los recursos disponibles de la máquina.

5) Son de sistema operativo, los podemos ver con htop.

### Clase 3 - 31/08/2021

Se menciono [Crawler](https://es.ryte.com/wiki/Crawler)

Python

yield <-> generador

Al generador se le pide un valor (next).

corrutinas: los-men-jugando-ajedrez
bart: persona-hilo-proceso

* threads. El planificador se encarga de desalojar los threads. Multitarea apropiativo.
* corrutinas: 1 solo thread., ellas mismas ceden el control. Multitarea colaborativa. En python se hace con el **await**. **Async def** permite generar corrutinas? 
* Las corrutinas entonces nos dan concurrencia. Peso de Thread en python 50kb, corrutina pesa 3kb.

condicion de carrera: 2 o mas acceden 

En ruby tenemos los Fiber que son similares a las corrutinas.

GUILD thread de SO que permite ejecutar hilos de usuario como hilos de SO y estos pueden ejecutarse en cada procesador.

