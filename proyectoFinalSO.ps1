function Show-Menu
{
     param (
           [string]$Title = 'DATA CENTER MANAGER'
     )
     cls
     Write-Host "================ $Title ================"
    
     Write-Host "1: Desplegar los 5 procesos que consumen más CPU en este momento."
     Write-Host "2: Desplegar los filesystems o discos conectados a la máquina."
     Write-Host "3: Desplegar el nombre y el tamaño del archivo más grande almacenado en un disco."
     Write-Host "4: Cantidad de memoria libre y cantidad del espacio de swap en uso."
     Write-Host "5: Número de conexiones de red activas actualmente."
     Write-Host "Q: Presione 'Q' para salir."
}

do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
           '1' {
                cls
                #el cmdlet Get-Process obtiene los procesos corriendo actualmente, ordenamos descendente para que ordene de mayor a menor y selecionamos los primeros 5
                Get-Process | sort CPU -Descending | Select-Object -First 5
           } '2' {
                cls
                #el cmdle Get-PSDrive devuelve todas los drives actuales de todos los proveedores disponibles.
                #el where se hace para que no traiga informacion irrelevante y el ft nos trae las columnas que queremos, en este caso nombre, tamano, usada y libre
                #para obtener el tamaño, sumamos el espacio usado en disco + el libre
                Get-PSDrive | Where {$_.Free -gt 0} | ft Name, @{n='Tamaño (bytes)'; e={$_.Used + $_.Free}}, Used, Free
           } '3' {
                #Pedimos al usuario la ruta donde se va a hacer la consulta, y la almacenamos en una variable para luego utilizarla.
                #Le mostramos la ruta para confirmar que ha sido almacenada de manera correcta.
                $discoFile = Read-Host "Ingrese el disco o filesystem"
                Write-Host "Directorio ingresado: $discoFile"              
                
                #Le mandamos la varibale con la ruta ingresada para que busque la carpeta o archivo, luego esos se ordenan de manera descendiente por su tamaño.
                #De esos, seleccionamos el primer archivo o carpeta; para finalmente mostrarlo en un formato de tabla con: su nombre, tamaño en megabytes y su trayectoria completa para saber en dónde está ubicado.
                Get-ChildItem -Path $discoFile -Recurse -file | sort -Descending -Property Length | Select-Object  * -First 1  |  ft  @{n='Nombre';e={$_.Name}},@{n='Tamaño (MB)';e={$_.Length / 1MB -as [int]}},@{n='Trayectoria';e={$_.Fullname}}
           } '4' {
                cls
		        #REFERENTE A MEMORIA
                $ramTotal=get-ciminstance -class "cim_physicalmemory" | % {$_.Capacity}
                $ramLibre=get-ciminstance Win32_OperatingSystem | Select FreePhysicalMemory
                
                #Usamos la clase Win32_OperatingSystem para recuperar informacion de la computadora
                $system = Get-WmiObject win32_OperatingSystem
                $totalPhysicalMem = $system.TotalVisibleMemorySize
                $freePhysicalMem = $system.FreePhysicalMemory

                #la memoria fisica usada la obtenemos al restarle a la memoria fisica total la memoria fisica libre
                $usedPhysicalMem = $totalPhysicalMem - $freePhysicalMem
                #para obtener la memoria fisica usada en porcentaje, dividimos la memoria fisica usada de la memoria fisica total. El ,1 al lado del 100 es para especificar que el resultado lo de con una cifra decimal
                $usedPhysicalMemPct = [math]::Round(($usedPhysicalMem / $totalPhysicalMem) * 100,1)
                
                #Para la memoria fisica libre en porcentaje simplemente a 100 le restamos el resultado de la formula anterior
                $freePhysicalMemPct = 100 - $usedPhysicalMemPct
                "Memoria Libre: $freePhysicalMem Bytes"
                "Memoria libre en porcentaje: $freePhysicalMemPct %"
                "Memoria en uso en porcentaje: $usedPhysicalMemPct %"

                Write-Host "`n...procesando"
                
        		#REFERENTE A SWAP
                #systeminfo nos da alguna informacion de hardware del sistema. para obtener informacion de paging memory on swap, filtramos los campos que tengan como cadena 'Memoria virtual'
		        systeminfo | select-string "Memoria virtual: "

                #Este filtro lo usamos para obtener el tamaño maximo en memoria virtual
                $maxSizeStr = systeminfo | select-string "Memoria virtual: tama"

                #Con este script, buscamos convertir a entero el resultado anterior
                $maxSize = [int][regex]::Matches($maxSizeStr, '[\d.]+').Value -replace "\.",""
                
                #Dado que el resultado anterior lo da en MB, debemos multiplicarlo por el valor 1048576 para convertirlo a Bytes
                $masizebytes = [int]($maxSize) * 1048576

                #Este filtro lo usamos para obtener el tamaño en uso en memoria virtual
                $inUseStr = systeminfo | select-string "Memoria virtual: en uso:"

                #Con este script, buscamos convertir a entero el resultado anterior
                $inUse = [int][regex]::Matches($inUseStr, '[\d.]+').Value -replace "\.",""

                #Dado que el resultado anterior lo da en MB, debemos multiplicarlo por el valor 1048576 para convertirlo a Bytes
                $inUseBytes = [int]($inUse) * 1048576

                #El porcentaje de uso en swap lo obtenemos dividiendo el tamaño en uso sobre el tamaño maximo * 100
                $swapUsage = ($inUse / $maxSize) * 100

                "`nTamano máximo del swap: $masizebytes Bytes"
                "Cantidad espacio swap en uso: $inUseBytes Bytes"
                "Porcentaje de uso en swap: $swapUsage %"

           } '5' {
                cls
                #El cmdlet Get-NetTCPConnection obtiene conexiones TCP actuales. Use este cmdlet para ver las propiedades de conexión TCP, como la dirección IP local o remota, el puerto local o remoto y el estado de la conexión.
                #Se hace el filtro where para especificar que muestre los registros cuyo campo State sea igual a Establecido
                Get-NetTCPConnection | where {$_.State -eq "Established"}
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')