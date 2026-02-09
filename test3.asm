.MODEL SMALL
.STACK 200H

.DATA
    PROMPT   DB 0DH, 0AH, 'Enter Large Number: $'
    RESULT   DB 0DH, 0AH, 'Output: $'
    ; حجز مساحة ضخمة (مثلاً 10,000 خانة) كأنها بلا حدود للمستخدم العادي
    BUFFER   DB 10000 DUP('$') 
    
.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    ; رسالة البدء
    LEA DX, PROMPT
    MOV AH, 09H
    INT 21H

    ; تهيئة السجلات (SI هو المؤشر الديناميكي)
    LEA SI, BUFFER
    XOR CX, CX          ; عداد الخانات (لإدارة المسح فقط)

READ_STEP:
    ; قراءة حرف بدون صدى (التحكم الكلي)
    MOV AH, 08H
    INT 21H

    ; 1. مفتاح Enter للإنهاء
    CMP AL, 0DH
    JE FINALIZE

    ; 2. مفتاح Backspace للمسح اللحظي
    CMP AL, 08H
    JE DO_BACKSPACE

    ; 3. التعامل مع الإشارة السالبة (فقط في الخانة الأولى)
    CMP AL, '-'
    JNE VERIFY_DIGIT
    CMP CX, 0
    JNE READ_STEP       ; تجاهل إذا لم تكن في البداية
    JMP COMMIT_CHAR

VERIFY_DIGIT:
    ; 4. التحقق من الأرقام فقط
    CMP AL, '0'
    JB READ_STEP
    CMP AL, '9'
    JA READ_STEP

COMMIT_CHAR:
    ; 5. التخزين اللحظي في الذاكرة
    MOV [SI], AL
    INC SI
    INC CX
    
    ; 6. الطباعة اللحظية (Echo)
    MOV DL, AL
    MOV AH, 02H
    INT 21H
    
    ; التأكد من عدم تجاوز حدود القطاع (Safety Check)
    CMP SI, 10000
    JAE FINALIZE        ; التوقف إذا امتلأ الـ Buffer تماماً
    
    JMP READ_STEP

DO_BACKSPACE:
    CMP CX, 0           ; هل المخزن فارغ؟
    JE READ_STEP
    
    DEC SI              ; عودة المؤشر في الذاكرة
    DEC CX              ; تقليل العداد
    MOV BYTE PTR [SI], '$' ; تنظيف الخانة
    
    ; مسح من الشاشة (الخدعة الكلاسيكية للمبرمجين)
    MOV AH, 02H
    MOV DL, 08H         ; عودة للخلف
    INT 21H
    MOV DL, ' '         ; طباعة مسافة لمسح الحرف
    INT 21H
    MOV DL, 08H         ; عودة للخلف مرة أخرى
    INT 21H
    JMP READ_STEP

FINALIZE:
    CMP CX, 0
    JE READ_STEP        ; منع الإدخال الفارغ

    ; طباعة سطر جديد والنتيجة
    LEA DX, RESULT
    MOV AH, 09H
    INT 21H

    LEA DX, BUFFER
    MOV AH, 09H         ; طباعة السلسلة الضخمة بطلقة واحدة
    INT 21H

    ; إنهاء
    MOV AH, 4CH
    INT 21H
MAIN ENDP

END MAIN