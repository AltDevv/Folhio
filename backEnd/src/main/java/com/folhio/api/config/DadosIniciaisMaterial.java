package com.folhio.api.config;

import com.folhio.api.entity.ModeloDocxMaterial;
import com.folhio.api.entity.QuestaoMaterial;
import com.folhio.api.repository.ModeloDocxMaterialRepository;
import com.folhio.api.repository.QuestaoMaterialRepository;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.folhio.api.config.CaminhosGeradorMaterial;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DadosIniciaisMaterial implements ApplicationRunner {

    private final QuestaoMaterialRepository questions;
    private final ModeloDocxMaterialRepository templates;
    private final ObjectMapper objectMapper;
    private final CaminhosGeradorMaterial enginePaths;

    public DadosIniciaisMaterial(
            QuestaoMaterialRepository questions,
            ModeloDocxMaterialRepository templates,
            ObjectMapper objectMapper,
            CaminhosGeradorMaterial enginePaths
    ) {
        this.questions = questions;
        this.templates = templates;
        this.objectMapper = objectMapper;
        this.enginePaths = enginePaths;
    }

    @Override
    public void run(ApplicationArguments args) {
        inserirModelosIniciais();
        inserirQuestoesIniciais();
        inserirQuestoesAdicionais();
    }

    private void inserirModelosIniciais() {
        List<ModeloDocxMaterial> defaults = List.of(
                new ModeloDocxMaterial(
                        "atividade_simples",
                        "Atividade simples",
                        "atividade",
                        "simples",
                        enginePaths.modeloDocx("atividade_simples.docx"),
                        "Modelo limpo para exercícios rápidos e revisão."
                ),
                new ModeloDocxMaterial(
                        "prova_formal",
                        "Prova formal",
                        "prova",
                        "formal",
                        enginePaths.modeloDocx("prova_formal.docx"),
                        "Modelo sóbrio para avaliações com cabeçalho e gabarito."
                ),
                new ModeloDocxMaterial(
                        "lista_compacta",
                        "Lista compacta",
                        "lista",
                        "compacta",
                        enginePaths.modeloDocx("lista_compacta.docx"),
                        "Modelo econômico para muitas questões em poucas páginas."
                ),
                new ModeloDocxMaterial(
                        "atividade_colorida",
                        "Atividade colorida",
                        "atividade",
                        "colorida",
                        enginePaths.modeloDocx("atividade_colorida.docx"),
                        "Modelo mais visual para exercícios leves e revisão de conteúdo."
                ),
                new ModeloDocxMaterial(
                        "atividade_infantil",
                        "Atividade infantil",
                        "atividade",
                        "ludica",
                        enginePaths.modeloDocx("atividade_infantil.docx"),
                        "Modelo com aparência mais amigável para anos iniciais."
                ),
                new ModeloDocxMaterial(
                        "lista_guiada",
                        "Lista guiada",
                        "lista",
                        "guiada",
                        enginePaths.modeloDocx("lista_guiada.docx"),
                        "Modelo com foco em resolução passo a passo e espaço de raciocínio."
                ),
                new ModeloDocxMaterial(
                        "revisao_rapida",
                        "Revisão rápida",
                        "atividade",
                        "revisao",
                        enginePaths.modeloDocx("revisao_rapida.docx"),
                        "Modelo para retomada objetiva antes de prova ou simulado."
                ),
                new ModeloDocxMaterial(
                        "simulado_objetivo",
                        "Simulado objetivo",
                        "prova",
                        "simulado",
                        enginePaths.modeloDocx("simulado_objetivo.docx"),
                        "Modelo para treino com questões objetivas e gabarito separado."
                ),
                new ModeloDocxMaterial(
                        "prova_compacta",
                        "Prova compacta",
                        "prova",
                        "compacta",
                        enginePaths.modeloDocx("prova_compacta.docx"),
                        "Modelo econômico para avaliações curtas e impressão simples."
                )
        );
        for (ModeloDocxMaterial template : defaults) {
            templates.findById(template.obterId())
                    .ifPresentOrElse(
                            current -> {
                                current.atualizarDadosCatalogo(template);
                                templates.save(current);
                            },
                            () -> templates.save(template)
                    );
        }
    }

    private void inserirQuestoesIniciais() {
        if (questions.count() > 0) {
            return;
        }
        questions.saveAll(List.of(
                questao("Matemática", "Frações", "6º ano", "Fácil", "multipla_escolha",
                        "Qual fração representa metade de uma pizza dividida em duas partes iguais?",
                        "1/2", "Metade corresponde a uma parte de duas partes iguais.", "frações;representação",
                        "1/2", "1/3", "2/3", "3/4"),
                questao("Matemática", "Frações", "6º ano", "Fácil", "multipla_escolha",
                        "Em uma caixa há 12 lápis. Ana usou 1/3 deles. Quantos lápis ela usou?",
                        "4", "Um terço de 12 é 12 dividido por 3, que resulta em 4.", "frações;parte de quantidade",
                        "3", "4", "6", "9"),
                questao("Matemática", "Frações", "6º ano", "Média", "multipla_escolha",
                        "Qual é o resultado de 1/4 + 2/4?",
                        "3/4", "As frações têm o mesmo denominador, então somamos os numeradores.", "frações;soma",
                        "2/8", "3/4", "3/8", "1/2"),
                questao("Matemática", "Frações", "6º ano", "Média", "multipla_escolha",
                        "João comeu 2/5 de uma barra de chocolate e Maria comeu 1/5. Que fração da barra foi consumida?",
                        "3/5", "Como os denominadores são iguais, 2/5 + 1/5 = 3/5.", "frações;soma",
                        "1/5", "2/10", "3/5", "4/5"),
                questao("Matemática", "Frações", "7º ano", "Média", "multipla_escolha",
                        "Qual fração é equivalente a 2/3?",
                        "4/6", "Multiplicando numerador e denominador por 2, obtemos 4/6.", "frações;equivalência",
                        "3/4", "4/6", "5/6", "2/6"),
                questao("Matemática", "Porcentagem", "7º ano", "Fácil", "multipla_escolha",
                        "Quanto é 50% de 80?",
                        "40", "50% representa metade. A metade de 80 é 40.", "porcentagem;metade",
                        "20", "30", "40", "50"),
                questao("Matemática", "Porcentagem", "7º ano", "Média", "multipla_escolha",
                        "Um produto de R$ 100,00 recebeu desconto de 15%. Qual é o valor do desconto?",
                        "R$ 15,00", "15% de 100 corresponde a 15 reais.", "porcentagem;desconto",
                        "R$ 10,00", "R$ 15,00", "R$ 20,00", "R$ 85,00"),
                questao("Matemática", "Porcentagem", "8º ano", "Média", "multipla_escolha",
                        "Uma turma tem 40 alunos, e 25% faltaram. Quantos alunos faltaram?",
                        "10", "25% é um quarto. Um quarto de 40 é 10.", "porcentagem;quantidade",
                        "5", "8", "10", "15"),
                questao("Matemática", "Operações", "5º ano", "Fácil", "multipla_escolha",
                        "Qual é o resultado de 48 + 27?",
                        "75", "Somando dezenas e unidades: 48 + 27 = 75.", "adição",
                        "65", "70", "75", "85"),
                questao("Matemática", "Operações", "5º ano", "Fácil", "multipla_escolha",
                        "Qual é o resultado de 9 x 7?",
                        "63", "A multiplicação 9 x 7 resulta em 63.", "multiplicação;tabuada",
                        "56", "63", "72", "81"),
                questao("Matemática", "Operações", "6º ano", "Média", "multipla_escolha",
                        "Resolva: 36 ÷ 4 + 8.",
                        "17", "Primeiro fazemos a divisão: 36 ÷ 4 = 9. Depois, 9 + 8 = 17.", "ordem das operações",
                        "11", "13", "17", "20"),
                questao("Matemática", "Geometria", "6º ano", "Fácil", "multipla_escolha",
                        "Quantos lados tem um hexágono?",
                        "6", "O prefixo hexa indica seis lados.", "polígonos",
                        "4", "5", "6", "8"),
                questao("Matemática", "Geometria", "7º ano", "Média", "multipla_escolha",
                        "Qual é a área de um retângulo com 8 cm de base e 3 cm de altura?",
                        "24 cm²", "A área do retângulo é base vezes altura: 8 x 3 = 24.", "área;retângulo",
                        "11 cm²", "16 cm²", "24 cm²", "48 cm²"),
                questao("Matemática", "Medidas", "5º ano", "Fácil", "multipla_escolha",
                        "Quantos centímetros há em 1 metro?",
                        "100", "Um metro corresponde a 100 centímetros.", "medidas;comprimento",
                        "10", "50", "100", "1000"),
                questao("Matemática", "Medidas", "6º ano", "Média", "multipla_escolha",
                        "Uma garrafa tem 2 litros de água. Quantos mililitros isso representa?",
                        "2000 ml", "Cada litro tem 1000 ml, então 2 litros são 2000 ml.", "medidas;capacidade",
                        "200 ml", "1000 ml", "1500 ml", "2000 ml"),
                questao("Matemática", "Equações", "7º ano", "Média", "multipla_escolha",
                        "Qual valor de x torna verdadeira a igualdade x + 5 = 12?",
                        "7", "Subtraindo 5 dos dois lados, x = 7.", "equações;primeiro grau",
                        "5", "6", "7", "17"),
                questao("Matemática", "Equações", "8º ano", "Média", "multipla_escolha",
                        "Resolva: 2x = 18.",
                        "9", "Dividindo os dois lados por 2, temos x = 9.", "equações;primeiro grau",
                        "6", "8", "9", "18"),
                questao("Matemática", "Razão e proporção", "8º ano", "Média", "multipla_escolha",
                        "Se 3 cadernos custam R$ 24,00, quanto custam 6 cadernos iguais?",
                        "R$ 48,00", "6 cadernos são o dobro de 3, então o preço também dobra.", "proporção",
                        "R$ 36,00", "R$ 42,00", "R$ 48,00", "R$ 60,00"),
                questao("Português", "Interpretação de texto", "5º ano", "Fácil", "multipla_escolha",
                        "Em um texto narrativo, quem conta a história é chamado de:",
                        "Narrador", "O narrador é a voz que apresenta os acontecimentos da narrativa.", "narrativa;narrador",
                        "Personagem", "Narrador", "Autor", "Leitor"),
                questao("Português", "Interpretação de texto", "6º ano", "Média", "multipla_escolha",
                        "A ideia principal de um texto é:",
                        "O assunto mais importante desenvolvido no texto", "A ideia principal resume o foco central do texto.", "leitura;ideia principal",
                        "Uma palavra difícil", "O nome do autor", "O assunto mais importante desenvolvido no texto", "A última frase do texto"),
                questao("Português", "Gramática", "5º ano", "Fácil", "multipla_escolha",
                        "Qual alternativa apresenta um substantivo comum?",
                        "cidade", "Substantivo comum nomeia seres de forma geral.", "substantivo",
                        "Brasil", "Ana", "cidade", "Amazonas"),
                questao("Português", "Gramática", "6º ano", "Fácil", "multipla_escolha",
                        "Na frase 'O menino correu', a palavra 'correu' é:",
                        "Verbo", "A palavra indica uma ação, portanto é verbo.", "verbo;classes de palavras",
                        "Substantivo", "Adjetivo", "Verbo", "Artigo"),
                questao("Português", "Gramática", "6º ano", "Média", "multipla_escolha",
                        "Qual palavra é um adjetivo na frase 'A casa azul fica na esquina'?",
                        "azul", "Azul caracteriza o substantivo casa.", "adjetivo",
                        "casa", "azul", "fica", "esquina"),
                questao("Português", "Pontuação", "5º ano", "Fácil", "multipla_escolha",
                        "Qual sinal de pontuação é usado ao final de uma pergunta?",
                        "Ponto de interrogação", "Perguntas são finalizadas com ponto de interrogação.", "pontuação",
                        "Ponto final", "Vírgula", "Ponto de interrogação", "Dois-pontos"),
                questao("Português", "Pontuação", "6º ano", "Média", "multipla_escolha",
                        "Na frase 'Maria, venha aqui', a vírgula foi usada para separar:",
                        "O vocativo", "Maria é a pessoa chamada, ou seja, vocativo.", "pontuação;vocativo",
                        "O sujeito", "O vocativo", "O verbo", "O predicado"),
                questao("Português", "Ortografia", "5º ano", "Fácil", "multipla_escolha",
                        "Qual palavra está escrita corretamente?",
                        "exceção", "A grafia correta é exceção.", "ortografia",
                        "execão", "excessão", "exceção", "eseção"),
                questao("Português", "Ortografia", "6º ano", "Média", "multipla_escolha",
                        "Complete corretamente: Eu _____ ao mercado ontem.",
                        "fui", "A forma verbal adequada no passado é 'fui'.", "ortografia;verbo",
                        "foi", "fui", "vamos", "iria"),
                questao("Português", "Produção textual", "7º ano", "Média", "multipla_escolha",
                        "Antes de escrever uma redação, é importante:",
                        "Planejar as ideias principais", "O planejamento ajuda a organizar o texto.", "produção textual;planejamento",
                        "Escrever sem revisar", "Copiar outro texto", "Planejar as ideias principais", "Usar apenas frases curtas"),
                questao("Português", "Coesão textual", "8º ano", "Média", "multipla_escolha",
                        "Na frase 'Pedro estudou muito, portanto foi bem na prova', a palavra 'portanto' indica:",
                        "Conclusão", "Portanto estabelece relação de conclusão.", "coesão;conectivos",
                        "Oposição", "Conclusão", "Tempo", "Dúvida"),
                questao("Português", "Figuras de linguagem", "8º ano", "Média", "multipla_escolha",
                        "Em 'A cidade acordou cedo', há exemplo de:",
                        "Personificação", "A cidade recebe uma ação humana: acordar.", "figuras de linguagem",
                        "Metáfora", "Personificação", "Comparação", "Hipérbole"),
                questao("Português", "Gêneros textuais", "6º ano", "Fácil", "multipla_escolha",
                        "Uma receita culinária tem como principal objetivo:",
                        "Orientar o preparo de algo", "Receitas apresentam instruções para preparar alimentos.", "gêneros;textos instrucionais",
                        "Contar uma aventura", "Defender uma opinião", "Orientar o preparo de algo", "Narrar lembranças"),
                questao("Português", "Gêneros textuais", "7º ano", "Média", "multipla_escolha",
                        "A principal característica de uma notícia é:",
                        "Informar sobre um fato atual ou relevante", "A notícia busca informar o leitor sobre fatos.", "gêneros;notícia",
                        "Ensinar uma receita", "Informar sobre um fato atual ou relevante", "Criar personagens fictícios", "Apresentar versos"),
                questao("Português", "Sintaxe", "7º ano", "Média", "multipla_escolha",
                        "Na frase 'Os alunos fizeram a atividade', o sujeito é:",
                        "Os alunos", "O sujeito indica quem praticou a ação.", "sintaxe;sujeito",
                        "fizeram", "a atividade", "Os alunos", "atividade"),
                questao("Português", "Sintaxe", "8º ano", "Média", "multipla_escolha",
                        "Na frase 'Choveu durante a noite', o sujeito é:",
                        "Inexistente", "Verbos que indicam fenômeno da natureza podem formar oração sem sujeito.", "sintaxe;oração sem sujeito",
                        "Choveu", "a noite", "durante", "Inexistente"),
                questao("Português", "Variação linguística", "8º ano", "Fácil", "multipla_escolha",
                        "A variação linguística mostra que a língua:",
                        "Muda conforme região, contexto e grupo social", "A língua varia de acordo com diferentes fatores sociais e culturais.", "variação linguística",
                        "É sempre igual", "Só existe na escrita", "Muda conforme região, contexto e grupo social", "Não tem regras"),
                questao("Português", "Acentuação", "6º ano", "Fácil", "multipla_escolha",
                        "Qual palavra é acentuada corretamente?",
                        "lápis", "A palavra lápis é paroxítona terminada em -is e recebe acento.", "acentuação",
                        "lapis", "lápis", "lapís", "lá pis")
        ));
    }

    private void inserirQuestoesAdicionais() {
        List<QuestaoMaterial> extras = List.of(
                identificadorQuestao("seed-cie-solar-001", "Ciências", "Sistema solar", "5º ano", "Fácil", "multipla_escolha",
                        "Qual astro é uma estrela e fornece luz e calor para a Terra?",
                        "Sol", "O Sol é a estrela central do Sistema Solar e emite luz própria.", "sistema solar;astro",
                        "Lua", "Sol", "Marte", "Terra"),
                identificadorQuestao("seed-cie-solar-002", "Ciências", "Sistema solar", "6º ano", "Média", "multipla_escolha",
                        "O movimento da Terra ao redor do Sol é chamado de:",
                        "Translação", "A translação é o movimento que a Terra realiza em torno do Sol.", "sistema solar;movimentos da terra",
                        "Rotação", "Translação", "Eclipse", "Maré"),
                identificadorQuestao("seed-cie-corpo-001", "Ciências", "Corpo humano", "5º ano", "Fácil", "multipla_escolha",
                        "Qual sistema do corpo humano é responsável por levar oxigênio e nutrientes pelo sangue?",
                        "Sistema circulatório", "O sistema circulatório transporta sangue, oxigênio e nutrientes pelo corpo.", "corpo humano;sistemas",
                        "Sistema digestório", "Sistema circulatório", "Sistema nervoso", "Sistema locomotor"),
                identificadorQuestao("seed-cie-corpo-002", "Ciências", "Corpo humano", "6º ano", "Média", "multipla_escolha",
                        "A digestão começa principalmente em qual parte do corpo?",
                        "Boca", "Na boca, os alimentos são mastigados e misturados à saliva, iniciando a digestão.", "digestão;corpo humano",
                        "Estômago", "Intestino", "Boca", "Pulmão"),
                identificadorQuestao("seed-cie-ambiente-001", "Ciências", "Meio ambiente", "6º ano", "Fácil", "multipla_escolha",
                        "Separar papel, plástico, vidro e metal para reaproveitamento é uma prática de:",
                        "Reciclagem", "A reciclagem transforma materiais usados em novos produtos.", "meio ambiente;reciclagem",
                        "Evaporação", "Poluição", "Reciclagem", "Fotossíntese"),
                identificadorQuestao("seed-cie-ambiente-002", "Ciências", "Meio ambiente", "7º ano", "Média", "multipla_escolha",
                        "Uma consequência do desmatamento é:",
                        "Perda de habitat de espécies", "O desmatamento remove a vegetação e afeta os seres vivos que dependem dela.", "meio ambiente;desmatamento",
                        "Aumento imediato da biodiversidade", "Perda de habitat de espécies", "Fim das chuvas em todo o planeta", "Diminuição da temperatura global"),
                identificadorQuestao("seed-hist-colonia-001", "História", "Brasil Colônia", "6º ano", "Fácil", "multipla_escolha",
                        "Qual produto teve grande importância econômica no início da colonização portuguesa no Brasil?",
                        "Pau-brasil", "O pau-brasil foi explorado por seu valor comercial e pela tinta avermelhada extraída da madeira.", "brasil colônia;economia",
                        "Café", "Pau-brasil", "Borracha", "Soja"),
                identificadorQuestao("seed-hist-colonia-002", "História", "Brasil Colônia", "7º ano", "Média", "multipla_escolha",
                        "As capitanias hereditárias foram criadas com o objetivo de:",
                        "Administrar e ocupar o território colonial", "Portugal dividiu o território para facilitar a ocupação e administração.", "brasil colônia;administração",
                        "Abolir a escravidão", "Industrializar o Brasil", "Administrar e ocupar o território colonial", "Criar universidades"),
                identificadorQuestao("seed-hist-cidad-001", "História", "Cidadania", "6º ano", "Fácil", "multipla_escolha",
                        "Participar de decisões coletivas e respeitar direitos e deveres é parte da:",
                        "Cidadania", "Cidadania envolve participação social, direitos e responsabilidades.", "cidadania;direitos",
                        "Monarquia", "Cidadania", "Geologia", "Navegação"),
                identificadorQuestao("seed-hist-cidad-002", "História", "Cidadania", "8º ano", "Média", "multipla_escolha",
                        "A Constituição de um país serve principalmente para:",
                        "Definir direitos, deveres e organização do Estado", "A Constituição estabelece regras fundamentais da sociedade e do Estado.", "constituição;cidadania",
                        "Organizar apenas feriados", "Definir direitos, deveres e organização do Estado", "Substituir todas as leis municipais", "Criar moedas estrangeiras"),
                identificadorQuestao("seed-geo-mapas-001", "Geografia", "Mapas", "5º ano", "Fácil", "multipla_escolha",
                        "Em um mapa, a rosa dos ventos ajuda a identificar:",
                        "Direções", "A rosa dos ventos indica direções como norte, sul, leste e oeste.", "mapas;orientação",
                        "Temperatura", "Direções", "Quantidade de chuva", "População"),
                identificadorQuestao("seed-geo-mapas-002", "Geografia", "Mapas", "6º ano", "Média", "multipla_escolha",
                        "A escala de um mapa indica:",
                        "A relação entre distância no mapa e distância real", "A escala mostra quantas vezes a realidade foi reduzida no mapa.", "mapas;escala",
                        "A cor do oceano", "A relação entre distância no mapa e distância real", "O nome dos países", "A altura das montanhas apenas"),
                identificadorQuestao("seed-geo-clima-001", "Geografia", "Clima", "6º ano", "Fácil", "multipla_escolha",
                        "Clima é o conjunto de condições atmosféricas observadas em uma região durante:",
                        "Um longo período", "O clima considera médias e padrões observados ao longo do tempo.", "clima;tempo atmosférico",
                        "Um minuto", "Um único dia", "Um longo período", "Uma manhã"),
                identificadorQuestao("seed-geo-urb-001", "Geografia", "Urbanização", "7º ano", "Média", "multipla_escolha",
                        "Urbanização é o processo relacionado ao crescimento:",
                        "Das cidades e da população urbana", "Urbanização envolve o aumento das cidades e das atividades urbanas.", "urbanização;cidades",
                        "Das florestas nativas", "Das cidades e da população urbana", "Dos rios", "Das geleiras"),
                identificadorQuestao("seed-ing-vocab-001", "Inglês", "Vocabulário", "5º ano", "Fácil", "multipla_escolha",
                        "Qual palavra em inglês significa 'livro'?",
                        "Book", "Book é a tradução de livro.", "vocabulário;objetos escolares",
                        "Table", "Book", "Chair", "Door"),
                identificadorQuestao("seed-ing-vocab-002", "Inglês", "Vocabulário", "6º ano", "Fácil", "multipla_escolha",
                        "A palavra 'teacher' significa:",
                        "Professor(a)", "Teacher é a pessoa que ensina.", "vocabulário;escola",
                        "Aluno", "Professor(a)", "Caderno", "Janela"),
                identificadorQuestao("seed-ing-present-001", "Inglês", "Simple present", "7º ano", "Média", "multipla_escolha",
                        "Complete: She _____ soccer every Saturday.",
                        "plays", "No simple present, usamos -s na terceira pessoa do singular.", "simple present;third person",
                        "play", "plays", "playing", "played"),
                identificadorQuestao("seed-ing-present-002", "Inglês", "Simple present", "7º ano", "Média", "multipla_escolha",
                        "Qual alternativa está na forma negativa correta?",
                        "I do not like coffee.", "Com I/you/we/they, usa-se do not para formar a negativa.", "simple present;negative",
                        "I not like coffee.", "I does not like coffee.", "I do not like coffee.", "I no like coffee."),
                identificadorQuestao("seed-mat-est-001", "Matemática", "Estatística", "7º ano", "Fácil", "multipla_escolha",
                        "Em uma pesquisa, a moda é o valor que:",
                        "Mais se repete", "A moda é o valor com maior frequência em um conjunto de dados.", "estatística;moda",
                        "É sempre o maior", "Mais se repete", "É sempre o menor", "Fica no meio obrigatoriamente"),
                identificadorQuestao("seed-mat-est-002", "Matemática", "Estatística", "8º ano", "Média", "multipla_escolha",
                        "Qual é a média de 6, 8 e 10?",
                        "8", "Somamos 6 + 8 + 10 = 24 e dividimos por 3, resultando em 8.", "estatística;média",
                        "6", "7", "8", "10"),
                identificadorQuestao("seed-mat-dec-001", "Matemática", "Números decimais", "6º ano", "Fácil", "multipla_escolha",
                        "Qual número decimal representa cinco décimos?",
                        "0,5", "Cinco décimos correspondem a 5/10, que é 0,5.", "decimais;representação",
                        "0,05", "0,5", "5,0", "50,0"),
                identificadorQuestao("seed-mat-dec-002", "Matemática", "Números decimais", "6º ano", "Média", "multipla_escolha",
                        "Quanto é 2,5 + 1,25?",
                        "3,75", "Somando as casas decimais corretamente, 2,50 + 1,25 = 3,75.", "decimais;adição",
                        "2,75", "3,25", "3,75", "4,00"),
                identificadorQuestao("seed-port-cron-001", "Português", "Crônica", "7º ano", "Fácil", "multipla_escolha",
                        "A crônica costuma tratar de fatos do cotidiano com linguagem:",
                        "Mais próxima do leitor", "A crônica frequentemente usa linguagem acessível e aborda situações do dia a dia.", "gêneros textuais;crônica",
                        "Sempre científica", "Mais próxima do leitor", "Apenas jurídica", "Sem opinião"),
                identificadorQuestao("seed-port-coer-001", "Português", "Coerência textual", "8º ano", "Média", "multipla_escolha",
                        "Um texto coerente é aquele que apresenta:",
                        "Ideias organizadas e sentido lógico", "A coerência garante que as partes do texto façam sentido entre si.", "coerência;textualidade",
                        "Frases sem relação", "Ideias organizadas e sentido lógico", "Apenas palavras difíceis", "Somente perguntas"),
                identificadorQuestao("seed-port-verbo-001", "Português", "Verbos", "7º ano", "Média", "multipla_escolha",
                        "Na frase 'Nós estudaremos amanhã', o verbo está no tempo:",
                        "Futuro", "Estudaremos indica uma ação que ainda acontecerá.", "verbos;tempos verbais",
                        "Presente", "Pretérito", "Futuro", "Imperativo"),
                identificadorQuestao("seed-cie-energia-001", "Ciências", "Energia", "8º ano", "Média", "multipla_escolha",
                        "Uma fonte de energia renovável é:",
                        "Energia solar", "A energia solar vem do Sol e pode ser renovada naturalmente.", "energia;fontes renováveis",
                        "Carvão mineral", "Petróleo", "Energia solar", "Gás natural"),
                identificadorQuestao("seed-geo-econ-001", "Geografia", "Atividades econômicas", "7º ano", "Média", "multipla_escolha",
                        "A agricultura pertence principalmente a qual setor da economia?",
                        "Setor primário", "O setor primário envolve atividades ligadas à extração e produção direta da natureza.", "economia;setores",
                        "Setor primário", "Setor secundário", "Setor terciário", "Setor financeiro")
        );
        for (QuestaoMaterial question : extras) {
            if (!questions.existsById(question.obterId())) {
                questions.save(question);
            }
        }
    }

    private QuestaoMaterial questao(
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String type,
            String statement,
            String correctAnswer,
            String explanation,
            String skillTags,
            String... options
    ) {
        try {
            return new QuestaoMaterial(
                    discipline,
                    subject,
                    schoolYear,
                    difficulty,
                    type,
                    statement,
                    objectMapper.writeValueAsString(List.of(options)),
                    correctAnswer,
                    explanation,
                    skillTags
            );
        } catch (JsonProcessingException error) {
            throw new IllegalStateException("Não foi possível preparar o seed de questões.", error);
        }
    }

    private QuestaoMaterial identificadorQuestao(
            String id,
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String type,
            String statement,
            String correctAnswer,
            String explanation,
            String skillTags,
            String... options
    ) {
        try {
            return new QuestaoMaterial(
                    id,
                    discipline,
                    subject,
                    schoolYear,
                    difficulty,
                    type,
                    statement,
                    objectMapper.writeValueAsString(List.of(options)),
                    correctAnswer,
                    explanation,
                    skillTags
            );
        } catch (JsonProcessingException error) {
            throw new IllegalStateException("Não foi possível preparar o seed de questões.", error);
        }
    }
}
