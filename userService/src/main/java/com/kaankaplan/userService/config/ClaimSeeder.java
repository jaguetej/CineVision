package com.kaankaplan.userService.config;

import com.kaankaplan.userService.dao.ClaimDao;
import com.kaankaplan.userService.entity.Claim;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class ClaimSeeder implements CommandLineRunner {

    private final ClaimDao claimDao;

    @Override
    public void run(String... args) {
        seedIfMissing("CUSTOMER");
        seedIfMissing("ADMIN");
    }

    private void seedIfMissing(String claimName) {
        if (claimDao.getClaimByClaimName(claimName) == null) {
            Claim claim = Claim.builder().claimName(claimName).build();
            claimDao.insert(claim);
            log.info("Claim sembrado: {}", claimName);
        }
    }
}
