
//@skip-check module-structure-method-in-regions
&НаКлиенте
Процедура УдалитьВсеРегистрации(Команда)
	УдалитьВсеРегистрацииНаСервере();
КонецПроцедуры

//@skip-check module-structure-method-in-regions
&НаСервере
Процедура УдалитьВсеРегистрацииНаСервере()
	
	Узлы = Новый Массив;
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	                   |	ОбменМеждуСистемамиБронирования.Ссылка КАК Ссылка
	                   |ИЗ
	                   |	ПланОбмена.ОбменМеждуСистемамиБронирования КАК ОбменМеждуСистемамиБронирования
	                   |ГДЕ
	                   |	НЕ ОбменМеждуСистемамиБронирования.ЭтотУзел"; 
					   
	Выборка = Запрос.Выполнить().Выбрать();  
	 
	Пока Выборка.Следующий() Цикл
	
		 Узлы.Добавить(Выборка.Ссылка);
	
	КонецЦикла;  
	 
	 
	Объекты = Новый Массив;
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	               |	Бронирования.Ссылка КАК Ссылка
	               |ИЗ
	               |	Документ.Бронирования КАК Бронирования";
					   
	Выборка = Запрос.Выполнить().Выбрать();  
	 
	Пока Выборка.Следующий() Цикл
	
		 Объекты.Добавить(Выборка.Ссылка);
	
	КонецЦикла;  
	 
	ПланыОбмена.УдалитьРегистрациюИзменений(Узлы, Объекты); 
	
	
КонецПроцедуры

//@skip-check module-structure-method-in-regions
&НаКлиенте
Процедура ВыгрузитьДанные(Команда)  
	
		Если Получатель.Пустая() Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Получатель должен быть заполнен";
			Сообщение.Поле = "Получатель";
			Сообщение.Сообщить();	
		    Возврат;
		КонецЕсли;
	
	АдресДанных = ВыгрузитьДанныеНаСервере();    
	
	ПараметрыДиалога = Новый ПараметрыДиалогаПолученияФайлов;
	
	ПолучитьФайлССервераАсинх(АдресДанных, "Выгрузка.xml", ПараметрыДиалога)
	
КонецПроцедуры

//@skip-check module-structure-method-in-regions
&НаСервере
Функция ВыгрузитьДанныеНаСервере() 
	
	Поток = Новый ПотокВПамяти;
	
	Запись = Новый ЗаписьXML;
	Запись.ОткрытьПоток(Поток);
	
	ЗаписьСообщения = ПланыОбмена.СоздатьЗаписьСообщения();	
	ЗаписьСообщения.НачатьЗапись(Запись, Получатель); 
	Выборка = ПланыОбмена.ВыбратьИзменения(Получатель, ЗаписьСообщения.НомерСообщения);
	
	Пока Выборка.Следующий() Цикл
		Данные =  Выборка.Получить();
		ЗаписатьXML(Запись, Данные)
	КонецЦикла; 
	
	ЗаписьСообщения.ЗакончитьЗапись();  
	
	Запись.Закрыть();
	
	Возврат ПоместитьВоВременноеХранилище(Поток.ЗакрытьИПолучитьДвоичныеДанные());
	
КонецФункции

//@skip-check module-structure-method-in-regions
&НаКлиенте
Асинх Процедура ЗагрузитьДанные(Команда) 
	
	ПараметрыДиалога = Новый ПараметрыДиалогаПомещенияФайлов;
	ПараметрыДиалога.Фильтр = "Файл выгрузки (*.xml)|*.xml";
	
	Результат = Ждать ПоместитьФайлНаСерверАсинх(,,, ПараметрыДиалога);
	
	Если Результат = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	Если Результат.ПомещениеФайлаОтменено Тогда
		Возврат;
	КонецЕсли;
	
   ЗагрузитьДанныеНаСервере(Результат.Адрес);

КонецПроцедуры

//@skip-check module-structure-method-in-regions
&НаСервере
 Процедура ЗагрузитьДанныеНаСервере(Адрес)
	 
	 ДвичныеДанные = ПолучитьИзВременногоХранилища(Адрес);
	 
	 Чтение = Новый ЧтениеXML;
	 Чтение.ОткрытьПоток(ДвичныеДанные.ОткрытьПотокДляЧтения());
	 
	 ЧтениеСообщения = ПланыОбмена.СоздатьЧтениеСообщения();
	 ЧтениеСообщения.НачатьЧтение(Чтение, ДопустимыйНомерСообщения.Очередной);
	 
	 Пока ВозможностьЧтенияXML(Чтение) Цикл
	 	Данные = ПрочитатьXML(Чтение);
		Если ТипЗнч(Данные) = Тип("ДокументОбъект.Бронирования") Тогда
		 	Данные.ОбменДанными.Отправитель = ЧтениеСообщения.Отправитель;		
		КонецЕсли;
		Данные.ОбменДанными.Загрузка = Истина;
		Данные.Записать();
	КонецЦикла;
	
	ЧтениеСообщения.ЗакончитьЧтение();
	
	Чтение.Закрыть();
	 
	   
		
КонецПроцедуры
