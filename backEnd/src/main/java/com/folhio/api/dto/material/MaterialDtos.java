package com.folhio.api.dto.material;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import java.util.List;

public final class MaterialDtos {
    private MaterialDtos() {
    }

    public record CatalogoMaterialResponse(
            List<String> disciplines,
            List<String> subjects,
            List<String> schoolYears,
            List<String> difficulties,
            List<ResumoModelo> templates
    ) {
    }

    public record ResumoModelo(
            String id,
            String name,
            String materialType,
            String styleCode,
            String description
    ) {
    }

    public record CriacaoMaterialRequest(
            @Size(max = 120) String title,
            @Size(max = 50) String materialType,
            @Size(max = 80) String discipline,
            @Size(max = 120) String subject,
            @Size(max = 40) String schoolYear,
            @Size(max = 40) String difficulty,
            @Size(max = 60) String templateId,
            @Size(max = 120) String teacherName,
            @Size(max = 120) String className,
            @Size(max = 500) String instructions,
            @Min(1) @Max(30) Integer questionCount,
            Boolean includeAnswerKey,
            Boolean shuffleQuestions,
            Boolean shuffleOptions
    ) {
    }

    public record CriacaoMaterialResponse(
            boolean success,
            String generatedMaterialId,
            String fileId,
            String fileName,
            String downloadUrl,
            String templateId,
            int questionCount,
            List<ResumoQuestaoGerada> questions
    ) {
    }

    public record ResumoMaterialGerado(
            String id,
            String title,
            String materialType,
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String templateId,
            int questionCount,
            String fileId,
            String fileName,
            String downloadUrl,
            String createdAt
    ) {
    }

    public record ResumoQuestaoGerada(
            String id,
            String discipline,
            String subject,
            String schoolYear,
            String difficulty,
            String statement
    ) {
    }
}
