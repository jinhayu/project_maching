<div style="padding: 20px; line-height: 1.7; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">

  <div style="background: linear-gradient(135deg, #02539a 0%, #3ecf8e 100%); padding: 30px; border-radius: 10px; color: white; text-align: center; margin-bottom: 25px;">
    <h1 style="margin: 0; font-size: 32px; letter-spacing: 1px;">Synergy</h1>
  </div>

 <div style="padding: 20px; line-height: 1.7; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">

  <h2 style="color: #02539a; border-bottom: 2px solid #3ecf8e; padding-bottom: 10px; margin-top: 0; margin-bottom: 20px;"> 프로젝트 개요 (Overview)</h2>
  
  <div style="margin-bottom: 30px; padding: 20px; background-color: #f8fbff; border-radius: 10px; border-left: 5px solid #02539a;">
    <p style="margin: 0;">
      <b>Synergy(시너지)</b>는 학부 간 경계를 허물고 창의적인 협업을 지원하기 위해 개발된 <b>Flutter 기반 모바일 플랫폼</b>이다. 
      단순한 프로젝트 관리를 넘어, 딥러닝 기반의 매칭 엔진과 AI 어시스턴트를 결합하여 사용자에게 최적의 팀원과 아이디어를 연결하는 지능형 생태계를 구축하는 것을 목표이다.
    </p>
  </div>
 
  
<div style="padding: 20px; line-height: 1.7; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">

  <h2 style="color: #02539a; border-bottom: 2px solid #3ecf8e; padding-bottom: 10px; margin-top: 0;"> 핵심 기술 상세 (Core Features & Dev Environment)</h2>

  <div style="margin-bottom: 30px; border: 1px solid #eef2f6; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 10px rgba(2, 83, 154, 0.05);">
    <div style="background: linear-gradient(135deg, #02539a 0%, #1a73e8 100%); color: white; padding: 12px 20px; font-weight: bold; display: flex; align-items: center;">
      <span style="font-size: 20px; margin-right: 10px;"></span> 지능형 매칭 엔진 (Recommendation Engine)
    </div>
    <div style="padding: 20px; background-color: #f8fbff;">
      <p style="margin-top: 0;"><b>사용자의 행동 데이터를 분석하여 최적의 프로젝트와 팀원을 추천하는 환경.</b></p>
      <ul style="padding-left: 20px; color: #444;">
        <li><b>알고리즘 모델:</b> NCF(Neural Collaborative Filtering) 기반 딥러닝 모델 적용</li>
        <li><b>실시간 연산:</b> EMA(지수 이동평균) 알고리즘을 통한 가중치 계산으로 최신 트렌드 반영</li>
        <li><b>데이터 파이프라인:</b> 사용자 행동(클릭, 검색 등)을 태그화하여 Supabase Edge Functions로 확률 연산</li>
        <li><b>주요 목표:</b> 데이터 누적을 통한 개인화 정교화 및 실시간 관심사 즉각 반영</li>
      </ul>
    </div>
  </div>

  <div style="margin-bottom: 30px; border: 1px solid #eef2f6; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 10px rgba(62, 207, 142, 0.05);">
    <div style="background: linear-gradient(135deg, #3ecf8e 0%, #02539a 100%); color: white; padding: 12px 20px; font-weight: bold; display: flex; align-items: center;">
      <span style="font-size: 20px; margin-right: 10px;"></span> AI 어시스턴트 (LLM 기반 가이드)
    </div>
    <div style="padding: 20px; background-color: #f5fff9;">
      <p style="margin-top: 0;"><b>사용자의 질문에 답하고 앱 이용을 돕는 전용 AI 환경.</b></p>
      <ul style="padding-left: 20px; color: #444;">
        <li><b>추론 엔진:</b> Groq API를 활용하여 응답 속도 및 서비스 안정성 최적화</li>
        <li><b>LLM 로직:</b> 앱/웹 구조 학습을 위한 전용 파인튜닝 로직 및 프롬프트 엔지니어링 적용</li>
        <li><b>보안 강화:</b> API Key 노출 방지를 위한 서버 측 프록시 환경 구축 및 안정적인 루틴 확보</li>
        <li><b>인터페이스:</b> 직관적인 사용자 질의응답을 위한 실시간 챗봇 UI 구현</li>
      </ul>
    </div>
  </div>

  <div style="margin-bottom: 10px; border: 1px solid #eef2f6; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 10px rgba(74, 85, 104, 0.05);">
    <div style="background-color: #4a5568; color: white; padding: 12px 20px; font-weight: bold; display: flex; align-items: center;">
      <span style="font-size: 20px; margin-right: 10px;"></span> 프로젝트 검색 및 관리 시스템
    </div>
    <div style="padding: 20px; background-color: #f7f9fc;">
      <p style="margin-top: 0;"><b>학부 간 협업을 지원하는 핵심 인프라 환경.</b></p>
      <ul style="padding-left: 20px; color: #444;">
        <li><b>데이터베이스:</b> Supabase PostgreSQL을 활용한 체계적인 관계형 데이터 관리</li>
        <li><b>스토리지:</b> 프로젝트 문서 및 파일 공유를 위한 Supabase Storage 통합</li>
        <li><b>검색 기능:</b> Full-text Search를 통한 중단/활성 프로젝트의 정교한 검색 지원</li>
        <li><b>협업 최적화:</b> 전공 역량 필터링 기반의 팀원 매칭 및 커뮤니티 리뷰 시스템</li>
      </ul>
    </div>
  </div>

</div>



<div style="padding: 20px; line-height: 1.7; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">

  <h2 style="color: #02539a; border-bottom: 2px solid #3ecf8e; padding-bottom: 10px; margin-top: 0;"> 개발 환경 설정 (Development Setup)</h2>
  <p>이 프로젝트를 로컬 환경에서 빌드하고 실행하기 위해 아래 단계를 수행 .</p>

  <div style="margin-bottom: 25px;">
    <h3 style="color: #02539a; font-size: 18px; margin-bottom: 10px;">1. 필수 요구 사양</h3>
    <ul style="padding-left: 20px; color: #444;">
      <li><b>Flutter SDK:</b> 3.24.0 이상 (Material 3 및 최신 테마 시스템 대응)</li>
      <li><b>Dart SDK:</b> 3.5.0 이상</li>
      <li><b>인프라 계정:</b> Supabase Project 및 Groq Cloud API 계정 필요</li>
    </ul>
  </div>

  <div style="margin-bottom: 25px;">
    <h3 style="color: #02539a; font-size: 18px; margin-bottom: 10px;">2. API 키 및 환경 변수 설정 (.env)</h3>
    <p>프로젝트 루트의 <code>assets/</code> 폴더 내에 <code>.env</code> 파일을 생성하고 아래 정보를 .</p>
    <div style="background-color: #f4f4f4; padding: 15px; border-radius: 8px; font-family: 'Courier New', Courier, monospace; font-size: 14px; border-left: 4px solid #3ecf8e;">
      SUPABASE_URL=your_supabase_url<br>
      SUPABASE_ANON_KEY=your_supabase_anon_key<br>
      GROQ_API_KEY=your_groq_api_key
    </div>
  </div>

<div style="padding: 20px; line-height: 1.7; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">
  
  <h3 style="color: #02539a; border-bottom: 2px solid #3ecf8e; padding-bottom: 10px; margin-top: 0; margin-bottom: 20px;">3. 필수 패키지 구성 (Dependencies)</h3>
  
  <ul style="list-style: none; padding: 0; margin: 0;">
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">flutter_dotenv:</b> 환경 변수 관리 (.env 설정)
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">supabase_flutter:</b> 백엔드 DB 및 인증 시스템 연동
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">table_calendar:</b> 앱 내 캘린더 UI 구현
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">flutter_local_notifications:</b> 로컬 알림 기능 지원
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">timezone:</b> 지역별 시간대 설정 및 처리
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">intl:</b> 날짜 형식화 및 다국어 지원
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">google_fonts:</b> 커스텀 글꼴(Noto Sans KR 등) 적용
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">flutter_launcher_icons:</b> 앱 아이콘 생성 및 관리
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">flutter_native_splash:</b> 앱 시작 시 스플래시 화면 구성
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">google_generative_ai:</b> Gemini AI 기능 연동
    </li>
    <li style="margin-bottom: 10px; padding-bottom: 10px; border-bottom: 1px solid #f0f0f0;">
      <b style="color: #02539a;">flutter_markdown:</b> 마크다운 형식의 텍스트 렌더링
    </li>
    <li style="margin: 0;">
      <b style="color: #02539a;">http:</b> 외부 서버와의 HTTP 통신
    </li>
  </ul>
</div>


  <div style="margin-bottom: 25px;">
    <h3 style="color: #02539a; font-size: 18px; margin-bottom: 10px;">4. 패키지 설치 및 의존성 해결</h3>
    <p>터미널에서 아래 명령어를 실행하여 핵심 라이브러리(Supabase, Dotenv, Google Fonts 등)를 설치.</p>
    <div style="background-color: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 8px; font-family: 'Courier New', Courier, monospace; font-size: 14px;">
      <span style="color: #66d9ef;">flutter</span> pub get
    </div>
  </div>




  <div style="margin-bottom: 25px;">
    <h3 style="color: #02539a; font-size: 18px; margin-bottom: 10px;">5. 핵심 기능별 추가 설정</h3>
    <div style="border-left: 3px solid #02539a; padding-left: 15px; margin-bottom: 15px;">
      <p style="margin: 0;"><b> 매칭 엔진 (NCF+EMA):</b></p>
      <span style="font-size: 14px; color: #666;">Supabase 대시보드에서 <code>user_actions</code> 테이블을 생성하고 RLS 보안 정책을 활성화.</span><br><br>
    </div>
    <div style="border-left: 3px solid #3ecf8e; padding-left: 15px; margin-bottom: 15px;">
      <p style="margin: 0;"><b>AI 어시스턴트:</b></p>
      <span style="font-size: 14px; color: #666;">Groq API 속도 제한(Rate Limit)을 피하기 위해 초당 요청 횟수를 확인.</span><br><br>
    </div>
    <div style="border-left: 3px solid #4a5568; padding-left: 15px;">
      <p style="margin: 0;"><b> 프로젝트 관리:</b></p>
      <span style="font-size: 14px; color: #666;">파일 업로드를 위해 Supabase Storage에 <code>project_files</code> 버킷을 생성.</span>
    </div>
  </div>

  <div style="margin-bottom: 10px;">
    <h3 style="color: #02539a; font-size: 18px; margin-bottom: 10px;">6. 실행 및 확인</h3>
    <p>모든 설정이 완료되면 아래 명령어로 앱을 구동.</p>
    <div style="background-color: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 8px; font-family: 'Courier New', Courier, monospace; font-size: 14px;">
      <span style="color: #66d9ef;">flutter</span> run
    </div>
  </div>

</div>
